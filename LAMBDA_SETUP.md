# Lambda + Discord 通知功能設定指南

## 功能說明

這個專案現在支援當圖片上傳到 S3 bucket 時，自動觸發 Lambda 函數發送 Discord 通知。

## 新增的資源

### 1. Lambda 函數
- **檔案位置**: `lambda/s3_discord_notification.py`
- **功能**: 監聽 S3 事件，發送 Discord 通知
- **支援格式**: .jpg, .jpeg, .png, .gif

### 2. Terraform 配置
- **IAM 角色**: Lambda 執行權限
- **S3 事件通知**: 監聽圖片上傳事件
- **Lambda 權限**: 允許 S3 觸發 Lambda

### 3. 前端功能
- **圖片上傳介面**: 支援多檔案選擇
- **預覽功能**: 上傳前預覽圖片
- **狀態顯示**: 上傳進度和結果

## 部署步驟

### 1. 初始化 Terraform
```bash
terraform init
```

### 2. 檢查配置
```bash
terraform plan
```

### 3. 部署資源
```bash
terraform apply
```

## 測試功能

### 方法 1: 使用前端介面
1. 開啟網站
2. 在「圖片上傳測試」區域選擇圖片
3. 點擊「上傳圖片」按鈕
4. 檢查 Discord 頻道是否收到通知

### 方法 2: 直接上傳到 S3
```bash
# 使用 AWS CLI 上傳圖片
aws s3 cp your-image.jpg s3://your-bucket-name/
```

## Discord 通知內容

通知包含以下資訊：
- 📸 檔案名稱
- 🗂️ 儲存貯體名稱
- ⏰ 上傳時間
- 📋 事件類型
- 🎨 美觀的 Discord Embed 格式

## 注意事項

1. **Discord Webhook**: 已預設使用提供的 webhook URL
2. **圖片格式**: 只支援 .jpg, .jpeg, .png, .gif
3. **權限**: Lambda 需要 CloudWatch Logs 和 S3 讀取權限
4. **成本**: Lambda 按執行次數計費，S3 事件通知免費

## 故障排除

### Lambda 函數未觸發
- 檢查 S3 事件通知配置
- 確認 Lambda 權限設定
- 查看 CloudWatch Logs

### Discord 通知未發送
- 檢查 webhook URL 是否正確
- 確認網路連線
- 查看 Lambda 執行日誌

### 前端上傳功能
- 目前是模擬上傳（需要額外配置 S3 直接上傳）
- 實際專案中需要配置 AWS SDK 或 API Gateway

## 擴展功能

可以考慮添加：
- 圖片壓縮和縮圖生成
- 檔案大小限制
- 上傳進度條
- 錯誤重試機制
- 多個 Discord 頻道支援
