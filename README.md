# S3 靜態網站 + CloudFront CDN 部署專案

這個專案展示如何使用 Terraform 部署一個安全的 S3 靜態網站，並透過 CloudFront CDN 提供全球加速服務。

## 🏗️ 架構概述

```
用戶 → CloudFront CDN → S3 Bucket (Private)
```

### 主要特色

- ✅ **S3 Private Bucket**: 禁止直接公開存取
- ✅ **CloudFront CDN**: 全球內容分發網路
- ✅ **Origin Access Control (OAC)**: 安全的 S3 存取方式
- ✅ **最佳權限控管**: 最小權限原則
- ✅ **自動化部署**: 使用 Terraform 管理基礎設施

## 📁 專案結構

```
.
├── src/
│   ├── index.html         # 靜態網站首頁
│   └── index.js          # JavaScript 功能
├── main.tf                # 主要 Terraform 配置
├── variables.tf           # 變數定義
├── outputs.tf             # 輸出值定義
├── terraform.tfvars.example # 變數範例檔案
├── .gitignore            # Git 忽略檔案
└── README.md              # 說明文件
```

## 🚀 快速開始

### 前置需求

1. **AWS CLI** 已安裝並配置
2. **Terraform** >= 1.0 已安裝
3. **AWS 帳戶** 具有適當權限

### 部署步驟

1. **複製變數檔案**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **編輯變數檔案** (可選)
   ```bash
   # 修改 terraform.tfvars 中的設定
   aws_region = "ap-northeast-1"
   environment = "production"
   bucket_name_prefix = "my-website"
   ```

3. **初始化 Terraform**
   ```bash
   terraform init
   ```

4. **檢視部署計畫**
   ```bash
   terraform plan
   ```

5. **執行部署**
   ```bash
   terraform apply
   ```

6. **取得網站 URL**
   ```bash
   terraform output website_url
   ```

## 🔒 安全性設計

### S3 Bucket 安全設定

- **Public Access Block**: 完全阻擋公開存取
- **Bucket Policy**: 只允許 CloudFront 存取
- **Server-Side Encryption**: AES256 加密
- **Versioning**: 啟用版本控制

### CloudFront 安全設定

- **Origin Access Control (OAC)**: 取代舊的 OAI
- **HTTPS Only**: 強制 HTTPS 重導向
- **Signed URLs**: 支援簽名 URL（可選）

### 權限控管最佳實踐

1. **最小權限原則**: 只授予必要的權限
2. **服務角色分離**: CloudFront 和 S3 使用不同的服務角色
3. **條件式存取**: 使用條件限制存取來源
4. **定期審查**: 定期檢查和更新權限設定

## 📊 成本優化

### CloudFront 價格等級

- **PriceClass_100**: 北美 + 歐洲（最便宜）
- **PriceClass_200**: 包含亞洲（中等）
- **PriceClass_All**: 全球所有位置（最貴）

### 快取策略

- **HTML**: 1 小時快取
- **CSS/JS**: 1 年快取
- **壓縮**: 啟用 Gzip 壓縮

## 🛠️ 管理指令

### 更新網站內容

```bash
# 修改 src/index.html 或 src/index.js 後
terraform apply
```

### 檢視資源狀態

```bash
terraform show
```

### 銷毀資源

```bash
terraform destroy
```

### 檢視 CloudFront 分配狀態

```bash
aws cloudfront get-distribution --id $(terraform output -raw cloudfront_distribution_id)
```

## 🔍 故障排除

### 常見問題

1. **網站無法存取**
   - 檢查 CloudFront 分配狀態（需要 10-15 分鐘部署）
   - 確認 S3 bucket 政策正確設定

2. **403 Forbidden 錯誤**
   - 檢查 Origin Access Control 設定
   - 確認 S3 bucket policy 允許 CloudFront 存取

3. **內容未更新**
   - 清除 CloudFront 快取
   - 檢查檔案 ETag 是否正確

### 清除 CloudFront 快取

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## 📈 監控和日誌

### CloudWatch 指標

- 請求數
- 錯誤率
- 快取命中率
- 資料傳輸量

### 存取日誌

- S3 存取日誌
- CloudFront 存取日誌

## 🔄 CI/CD 整合

### GitHub Actions 範例

```yaml
name: Deploy to S3
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## 📚 相關資源

- [AWS S3 靜態網站託管](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront 開發者指南](https://docs.aws.amazon.com/cloudfront/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)

## 📄 授權

此專案僅供學習和研究使用。
