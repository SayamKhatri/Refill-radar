from datetime import datetime, timedelta
import sys, json, time
import pyspark.sql.functions as F
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from functools import reduce
import boto3
from pyspark.sql.window import Window

sc    = SparkContext()
glue  = GlueContext(sc)
spark = glue.spark_session

# Job Parameters
args = getResolvedOptions(
    sys.argv,
    ['JOB_NAME',
     'redshift_temp_dir',
     'redshift_conn',
     'run_date',
     'redshift_jdbc_url',
     'redshift_iam_role',
     'redshift_secret_arn',
     'redshift_workgroup']
)

run_dt = (datetime.utcnow() - timedelta(days=0)).strftime('%Y-%m-%d')
yyyy, mm, dd = run_dt.split('-')
print(f"Running ETL for: {run_dt}")

# Secret Manager 
sm = boto3.client('secretsmanager')
secret_bin = sm.get_secret_value(SecretId=args['redshift_secret_arn'])['SecretString']
secret     = json.loads(secret_bin)
jdbc_user  = secret['username']
jdbc_pass  = secret['password']

# Redshift SQL Execution
def run_redshift_sql(sql_text):
    rs = boto3.client('redshift-data', region_name='us-east-1')
    resp = rs.execute_statement(
        WorkgroupName = args['redshift_workgroup'],
        Database      = 'dev',
        SecretArn     = args['redshift_secret_arn'],
        Sql           = sql_text
    )

    stmt_id = resp['Id']
    print(f"Running: {sql_text.strip()}")

    while True:
        desc = rs.describe_statement(Id=stmt_id)
        status = desc['Status']

        if status == 'FINISHED':
            print("Procedure completed")
            print(f"{sql_text}: merged into warehouse\n")
            break
        elif status in ('FAILED', 'ABORTED'):
            raise RuntimeError(f"Procedure failed: {desc.get('Error', 'Unknown error')}")
        time.sleep(5)

# Validation Function 
QUARANTINE_ROOT = "s3://refill-radar-bad-records"

def validate_df(df, pk_cols, tbl):
    window_cols = pk_cols + (['event_time'] if 'event_time' in df.columns else [])
    df_nodup = df.dropDuplicates(window_cols)

    not_null_cond = reduce(lambda x, y: x & y, [F.col(c).isNotNull() for c in pk_cols])
    good = df_nodup.filter(not_null_cond)
    bad  = df_nodup.subtract(good)

    if bad.count():
        q_path = f"{QUARANTINE_ROOT}/{tbl}/year={yyyy}/month={mm}/day={dd}"
        bad.write.mode("append").parquet(q_path)
        print(f"{tbl}: quarantined {bad.count()} bad rows → {q_path}")

    return good if good.count() > 0 else None

# Deduplication Function 
def deduplicate_latest(df, pk_cols, time_col):
    window_spec = Window.partitionBy(*pk_cols).orderBy(F.col(time_col).desc())
    return df.withColumn("rn", F.row_number().over(window_spec)).filter(F.col("rn") == 1).drop("rn")

# Table Config 
TABLE_CONFIG = [
    ('products'          , ['product_id'],         'sp_merge_dim_product',     'event_time'),
    ('stores'            , ['store_id'],           'sp_merge_dim_store',       'event_time'),
    ('cashiers'          , ['cashier_id'],         'sp_merge_dim_cashier',     'event_time'),
    ('promotions'        , ['promotion_id'],       'sp_merge_dim_promotion',   'event_time'),
    ('payment_methods'   , ['payment_method_id'],  'sp_merge_dim_payment_method', 'event_time'),
    ('inventory'         , ['product_id'],         'sp_merge_fact_inventory',  'last_updated'),
    ('sales_transactions', ['transaction_id'],     'sp_load_fact_sales',       None)  
]


for lake_tbl, pk_cols, sp_name, time_col in TABLE_CONFIG:
    print(f"Processing {lake_tbl}")

    df = (spark.table(f"hasp_lake.{lake_tbl}")
              .filter(F.col("partition_0") == yyyy)
              .filter(F.col("partition_1") == mm)
              .filter(F.col("partition_2") == dd))

    valid_df = validate_df(df, pk_cols, lake_tbl)
    if valid_df is None:
        print(f"{lake_tbl}: No valid data to load")
        continue

    if time_col:
        valid_df = deduplicate_latest(valid_df, pk_cols, time_col)
        print(f"{lake_tbl}: deduplicated to {valid_df.count()} latest records")

    stg_name = f"stg_{lake_tbl}"
    (valid_df.write
        .format("jdbc")
        .option("url", args['redshift_jdbc_url'])
        .option("dbtable", stg_name)
        .option("user", jdbc_user)
        .option("password", jdbc_pass)
        .option("driver", "com.amazon.redshift.jdbc.Driver")
        .mode("overwrite")
        .save())

    print(f"{lake_tbl}: staged {valid_df.count()} rows → {stg_name}")
    run_redshift_sql(f"CALL hasp_dw.{sp_name}();")
