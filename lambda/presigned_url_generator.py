import json
import boto3
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    """
    生成 S3 預簽名上傳 URL
    """
    try:
        # 解析請求參數
        body = json.loads(event['body']) if 'body' in event else event
        file_name = body.get('fileName', '')
        file_type = body.get('fileType', 'image/jpeg')
        
        if not file_name:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS'
                },
                'body': json.dumps({
                    'error': 'fileName is required'
                })
            }
        
        # 獲取 S3 bucket 名稱
        bucket_name = os.environ['S3_BUCKET_NAME']
        
        # 生成唯一檔案名稱
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_file_name = f"uploads/{timestamp}_{file_name}"
        
        # 創建 S3 客戶端，指定正確的區域端點
        s3_client = boto3.client(
            's3',
            region_name='ap-east-2',
            endpoint_url='https://s3.ap-east-2.amazonaws.com'
        )
        
        # 生成預簽名 URL (有效期 1 小時)
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': unique_file_name,
                'ContentType': file_type
            },
            ExpiresIn=3600  # 1 小時
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({
                'presignedUrl': presigned_url,
                'fileName': unique_file_name,
                'expiresIn': 3600
            })
        }
        
    except Exception as e:
        print(f"Error generating presigned URL: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'Internal server error: {str(e)}'
            })
        }
