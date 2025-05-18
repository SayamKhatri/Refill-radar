-- parquet

COPY hasp_dw.table
FROM 's3://bucket/folder/path'
IAM_ROLE 'arn:aws:iam::account-id:role/redshift-role'
FORMAT AS PARQUET;

-- csv

COPY hasp_dw.table
FROM 's3://bucket/folder/path'
IAM_ROLE 'arn:aws:iam::account-id:role/redshift-role'
FORMAT AS CSV
IGNOREHEADER 1/0
DELIMITER ',';
