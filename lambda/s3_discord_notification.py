import json
import urllib3
import boto3

def lambda_handler(event, context):
    # 1. 解析 S3 事件資訊
    print("Received event: " + json.dumps(event))
    
    # 從事件中獲取 S3 相關資訊
    for record in event['Records']:
        # 確認是 S3 事件
        if record['eventSource'] != 'aws:s3':
            continue
            
        s3_info = record['s3']
        bucket_name = s3_info['bucket']['name']
        object_key = s3_info['object']['key']
        event_time = record['eventTime']
        event_name = record['eventName']  # 例如: ObjectCreated:Put
        
        # 2. 準備 Discord 訊息內容
        message_content = f"📸 有新圖片上傳到 S3 囉！\n\n**檔案名稱**: {object_key}\n**儲存貯體**: {bucket_name}\n**上傳時間**: {event_time}\n**事件類型**: {event_name}"
        
        # 3. Discord Webhook 資料
        webhook_url = "https://discord.com/api/webhooks/1307026207325552781/yiAZaCxjkc_z8VQ4NhXMYYYZ0JaHudsy8qB1PzHT3uk7vncEghXEbBigSDoRrOPoC6kT"
        
        discord_data = {
            "content": message_content,
            "username": "S3 圖片上傳通知機器人",
            "embeds": [
                {
                    "title": "圖片上傳成功 🎉",
                    "description": f"檔案 `{object_key}` 已成功上傳到 S3",
                    "color": 5814783,  # Discord 的藍色
                    "fields": [
                        {
                            "name": "儲存貯體",
                            "value": bucket_name,
                            "inline": True
                        },
                        {
                            "name": "檔案名稱",
                            "value": object_key,
                            "inline": True
                        },
                        {
                            "name": "時間",
                            "value": event_time,
                            "inline": False
                        }
                    ],
                    "thumbnail": {
                        "url": "https://cdn-icons-png.flaticon.com/512/4712/4712035.png"
                    }
                }
            ]
        }
        
        # 4. 發送請求到 Discord Webhook
        http = urllib3.PoolManager()
        
        try:
            response = http.request(
                'POST',
                webhook_url,
                body=json.dumps(discord_data),
                headers={'Content-Type': 'application/json'}
            )
            
            print(f"Discord webhook response status: {response.status}")
            
            if response.status == 204:
                return {
                    'statusCode': 200,
                    'body': json.dumps('Notification sent to Discord successfully!')
                }
            else:
                print(f"Failed to send notification. Status: {response.status}")
                return {
                    'statusCode': response.status,
                    'body': json.dumps('Failed to send notification to Discord')
                }
                
        except Exception as e:
            print(f"Error sending to Discord: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error: {str(e)}')
            }
