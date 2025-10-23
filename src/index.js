// S3 靜態網站 JavaScript 功能
let clickCount = 0;

// 增加點擊計數器
function incrementCounter() {
    clickCount++;
    document.getElementById('counter').textContent = `點擊次數: ${clickCount}`;
    
    // 添加動畫效果
    const counter = document.getElementById('counter');
    counter.style.transform = 'scale(1.2)';
    counter.style.color = '#ff6b6b';
    
    setTimeout(() => {
        counter.style.transform = 'scale(1)';
        counter.style.color = '#28a745';
    }, 200);
}

// 顯示當前時間
function showTime() {
    const now = new Date();
    const timeString = now.toLocaleString('zh-TW', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
    
    const timeDisplay = document.getElementById('timeDisplay');
    timeDisplay.innerHTML = `⏰ 當前時間: ${timeString}`;
    timeDisplay.style.display = 'block';
    
    // 3秒後隱藏
    setTimeout(() => {
        timeDisplay.style.display = 'none';
    }, 3000);
}

// 變換背景顏色
function changeColor() {
    const colors = [
        'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
        'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
        'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
        'linear-gradient(135deg, #fa709a 0%, #fee140 100%)'
    ];
    
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    document.body.style.background = randomColor;
}

// API Gateway 配置
const API_GATEWAY_URL = 'REPLACE_WITH_API_GATEWAY_URL';

// 使用預簽名 URL 上傳到 S3
async function uploadImages() {
    const fileInput = document.getElementById('imageUpload');
    const files = fileInput.files;
    const statusDiv = document.getElementById('uploadStatus');
    const imagesDiv = document.getElementById('uploadedImages');
    
    if (files.length === 0) {
        showStatus('請先選擇圖片檔案！', 'error');
        return;
    }
    
    showStatus('正在準備上傳...', 'info');
    
    // 清空之前的圖片預覽
    imagesDiv.innerHTML = '';
    
    // 上傳每個檔案
    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        if (!file.type.startsWith('image/')) {
            showStatus(`❌ 檔案 "${file.name}" 不是有效的圖片格式`, 'error');
            continue;
        }
        
        try {
            // 顯示圖片預覽
            const reader = new FileReader();
            reader.onload = function(e) {
                const img = document.createElement('img');
                img.src = e.target.result;
                img.className = 'uploaded-image';
                img.alt = file.name;
                imagesDiv.appendChild(img);
            };
            reader.readAsDataURL(file);
            
            showStatus(`正在獲取上傳 URL "${file.name}"...`, 'info');
            
            // 1. 請求預簽名 URL
            const response = await fetch(API_GATEWAY_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    fileName: file.name,
                    fileType: file.type
                })
            });
            
            if (!response.ok) {
                throw new Error(`API 請求失敗: ${response.status}`);
            }
            
            const data = await response.json();
            const { presignedUrl, fileName } = data;
            
            showStatus(`正在上傳 "${file.name}" 到 S3...`, 'info');
            
            // 2. 使用預簽名 URL 上傳到 S3
            const uploadResponse = await fetch(presignedUrl, {
                method: 'PUT',
                headers: {
                    'Content-Type': file.type,
                },
                body: file
            });
            
            if (!uploadResponse.ok) {
                throw new Error(`S3 上傳失敗: ${uploadResponse.status}`);
            }
            
            showStatus(`✅ 圖片 "${file.name}" 上傳成功！Discord 通知已發送。`, 'success');
            console.log(`📸 圖片上傳成功: ${fileName}`);
            console.log('🔔 S3 事件已觸發 Lambda 函數，Discord 通知已發送');
            
        } catch (error) {
            console.error('上傳失敗:', error);
            showStatus(`❌ 上傳 "${file.name}" 失敗: ${error.message}`, 'error');
        }
    }
    
    // 清空檔案選擇
    fileInput.value = '';
}

// 顯示狀態訊息
function showStatus(message, type) {
    const statusDiv = document.getElementById('uploadStatus');
    statusDiv.innerHTML = message;
    statusDiv.style.display = 'block';
    
    // 根據類型設定顏色
    switch(type) {
        case 'success':
            statusDiv.style.color = '#28a745';
            statusDiv.style.backgroundColor = '#d4edda';
            statusDiv.style.borderColor = '#c3e6cb';
            break;
        case 'error':
            statusDiv.style.color = '#dc3545';
            statusDiv.style.backgroundColor = '#f8d7da';
            statusDiv.style.borderColor = '#f5c6cb';
            break;
        case 'info':
        default:
            statusDiv.style.color = '#0c5460';
            statusDiv.style.backgroundColor = '#d1ecf1';
            statusDiv.style.borderColor = '#bee5eb';
            break;
    }
    
    // 3秒後隱藏訊息
    setTimeout(() => {
        statusDiv.style.display = 'none';
    }, 3000);
}

// 頁面載入完成後的初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 S3 靜態網站已載入完成！');
    
    // 添加一些互動效果
    const container = document.querySelector('.container');
    container.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-5px)';
        this.style.transition = 'transform 0.3s ease';
    });
    
    container.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
    });
    
    // 顯示載入完成訊息
    setTimeout(() => {
        const info = document.querySelector('.info');
        info.innerHTML += '<p style="color: #28a745; margin-top: 10px;">✅ JavaScript 功能已啟用</p>';
    }, 1000);
    
    // 添加檔案選擇事件監聽器
    const fileInput = document.getElementById('imageUpload');
    fileInput.addEventListener('change', function() {
        const files = this.files;
        if (files.length > 0) {
            console.log(`📁 已選擇 ${files.length} 個檔案`);
            Array.from(files).forEach(file => {
                console.log(`- ${file.name} (${file.type}, ${file.size} bytes)`);
            });
        }
    });
});
