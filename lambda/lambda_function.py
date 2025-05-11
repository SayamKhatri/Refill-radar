import base64
import json
import boto3
import pandas as pd
from io import StringIO
import uuid
from datetime import datetime, timedelta
import os


threshold_df = None


S3_BUCKET = os.environ['S3_BUCKET']
S3_KEY = os.environ['S3_KEY']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']


sns = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')
alerts_table = dynamodb.Table('stockout_alerts')


def log_alert_to_dynamodb(product_id, product_name, quantity, threshold):
    alert_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    ttl = int((datetime.utcnow() + timedelta(days=7)).timestamp())  # auto-expire after 7 days

    alerts_table.put_item(Item={
        'alert_id': alert_id,
        'product_id': product_id,
        'product_name': product_name,
        'quantity': quantity,
        'threshold': threshold,
        'alert_time': now,
        'ttl_expiration': ttl
    })

def load_thresholds():
    global threshold_df
    if threshold_df is None:
        s3 = boto3.client('s3')
        obj = s3.get_object(Bucket=S3_BUCKET, Key=S3_KEY)
        csv_data = obj['Body'].read().decode('utf-8')
        threshold_df = pd.read_csv(StringIO(csv_data))
    return threshold_df

def send_stockout_email(product_id, product_name, current_qty, threshold):
    subject = f"Stock Alert: {product_name} (ID: {product_id})"
    message = (
        f"*Stock Alert Notification*\n\n"
        f"Product: {product_name} (ID: {product_id})\n"
        f"Available Quantity: {current_qty}\n"
        f"Threshold Level: {threshold}\n\n"
        f"Action Required: Please initiate restocking immediately.\n\n"
        f"Sent by: Real-time Inventory Monitoring System"
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message
    )

def lambda_handler(event, context):
    thresholds = load_thresholds()

    for record in event['Records']:
        try:
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            change = json.loads(payload)
        except Exception as e:
            print("Failed to parse record:", e)
            continue

        after = change.get('data') or change.get('after')
        if not after:
            continue

        product_id = int(after.get('product_id'))
        current_qty = int(after.get('quantity_available'))

        product_row = thresholds[thresholds['product_id'] == product_id]
        if product_row.empty:
            print(f"Unknown product ID: {product_id}")
            continue

        threshold = int(product_row['stockout_threshold'].values[0])
        product_name = product_row['name'].values[0]

        if current_qty <= threshold:
            print(f"ALERT: {product_name} (ID: {product_id}) is low (qty = {current_qty}, threshold = {threshold})")
            send_stockout_email(product_id, product_name, current_qty, threshold)
            log_alert_to_dynamodb(product_id, product_name, current_qty, threshold)
        else:
            print(f"OK: {product_name} (ID: {product_id}) qty = {current_qty}, threshold = {threshold}")

    return {'statusCode': 200}
