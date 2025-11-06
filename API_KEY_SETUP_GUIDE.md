# 🔑 Hướng dẫn cài đặt Gemini API Key

## 📝 Tổng quan

Ứng dụng Smart Home sử dụng **Gemini AI** (Google) để xử lý điều khiển giọng nói thông minh. Bạn cần có API key để sử dụng tính năng này.

---

## 🎯 Bước 1: Lấy Gemini API Key

### Cách 1: Sử dụng API Key có sẵn (Default)
Ứng dụng đã được cấu hình với API key mặc định:
```
AIzaSyCVaAcxkhRJeSHffVwtD3Mwc1xWS02aVuU
```

⚠️ **Lưu ý:**
- API key này có **giới hạn quota** (số request/ngày)
- Nếu nhiều người dùng cùng dùng key này, có thể bị **vượt quota**
- Khuyến nghị tạo API key riêng cho bản thân

### Cách 2: Tạo API Key riêng (Khuyến nghị)

1. Truy cập: **https://aistudio.google.com/app/apikey**

2. Đăng nhập bằng **Google Account**

3. Click nút **"Create API Key"**

4. Chọn:
   - **Create API key in new project** (tạo project mới)
   - Hoặc chọn project có sẵn

5. Copy API key (bắt đầu với `AIza...`)

6. ⚠️ **QUAN TRỌNG:**
   - API key có định dạng: `AIzaSy...` (39 ký tự)
   - Không chia sẻ API key với người khác
   - Không commit API key lên GitHub public repo

---

## ⚙️ Bước 2: Cài đặt API Key trong App

### Phương pháp 1: Qua giao diện Settings (Đơn giản nhất)

1. Mở ứng dụng Smart Home

2. Vào tab **"Hồ sơ"** (Profile) ở bottom navigation

3. Click vào **"Cài đặt API Key (Gemini AI)"**

4. Nhập API key của bạn vào ô văn bản

5. Click nút **"Test API Key"** để kiểm tra (optional)

6. Click nút **"Lưu"**

7. ✅ Thành công! API key đã được lưu và AI Voice Service sẽ tự động reload

### Phương pháp 2: Thay đổi trong code (Cho Developer)

1. Mở file `lib/config/ai_config.dart`

2. Thay đổi dòng `_defaultApiKey`:
   ```dart
   static const String _defaultApiKey = 'YOUR_API_KEY_HERE';
   ```

3. Rebuild ứng dụng: `flutter run`

---

## 🧪 Bước 3: Kiểm tra API Key hoạt động

### Test bằng Voice Control

1. Mở ứng dụng Smart Home

2. Click nút **microphone (🎤)** ở màn hình Home

3. Nói một lệnh đơn giản:
   - **"Bật đèn"**
   - **"Tắt quạt"**
   - **"Nhiệt độ bao nhiêu?"**

4. ✅ Nếu AI phản hồi đúng → API key hoạt động!

5. ❌ Nếu lỗi:
   - Kiểm tra kết nối Internet
   - Kiểm tra API key có đúng định dạng không
   - Kiểm tra quota còn không (vào Google AI Studio)

---

## 🛠️ Troubleshooting

### Lỗi: "AI Service chưa được khởi tạo"
**Nguyên nhân:** API key chưa được load hoặc không hợp lệ

**Giải pháp:**
1. Vào **Profile > Cài đặt API Key**
2. Nhập lại API key
3. Click **Test API Key**
4. Nếu test OK → Click **Lưu**

### Lỗi: "API request timeout"
**Nguyên nhân:** 
- Kết nối Internet chậm
- API server Google bị quá tải

**Giải pháp:**
- Kiểm tra WiFi/4G
- Thử lại sau vài giây

### Lỗi: "Quota exceeded" (vượt quota)
**Nguyên nhân:** Đã dùng hết số request miễn phí trong ngày

**Giải pháp:**
1. Đợi 24 giờ để quota reset
2. Hoặc nâng cấp plan tại Google AI Studio
3. Hoặc tạo API key mới (project mới)

### Lỗi: "API key không hợp lệ"
**Nguyên nhân:** 
- API key sai định dạng
- API key bị revoke
- API key không được enable cho Gemini API

**Giải pháp:**
1. Kiểm tra API key bắt đầu bằng `AIza`
2. Kiểm tra độ dài ~39 ký tự
3. Vào Google AI Studio tạo key mới

---

## 📊 Thông tin kỹ thuật

### API Configuration
- **Model:** `gemini-2.0-flash-exp` (Gemini 2.0 Flash Experimental)
- **Temperature:** `0.1` (tập trung, ít sáng tạo)
- **Max Tokens:** `500` (đủ cho control commands)
- **Timeout:** `10 seconds`

### Lưu trữ API Key
- **Phương thức:** `SharedPreferences` (local device storage)
- **Key name:** `gemini_api_key`
- **Encryption:** ❌ Không mã hóa (tránh lưu API key nhạy cảm production)

### Tự động Reload
Khi bạn thay đổi API key trong Settings:
1. Key được lưu vào `SharedPreferences`
2. `AiVoiceService` tự động load key mới khi khởi tạo
3. Lần request tiếp theo sẽ dùng key mới

---

## 🔒 Bảo mật

### ⚠️ CẢNH BÁO

1. **Không chia sẻ API key** với người khác
2. **Không commit API key** lên GitHub public repo
3. **Không để API key** trong code nếu share source code

### ✅ Best Practices

1. **Tạo API key riêng** cho mỗi device/người dùng
2. **Enable quota monitoring** tại Google AI Studio
3. **Revoke API key cũ** nếu không dùng nữa
4. **Sử dụng Environment Variables** cho production apps

---

## 📚 Tài liệu tham khảo

- **Google AI Studio:** https://aistudio.google.com/
- **Gemini API Docs:** https://ai.google.dev/docs
- **API Key Management:** https://aistudio.google.com/app/apikey
- **Pricing & Quotas:** https://ai.google.dev/pricing

---

## 💡 Tips

### Tiết kiệm Quota
App đã được tối ưu để tiết kiệm API calls:
- Chỉ gửi sensor data khi cần (query về sensors)
- Không gửi sensor data cho device control commands
- Timeout sau 10s để tránh request treo

### Monitoring Usage
1. Vào https://aistudio.google.com/
2. Click vào API key của bạn
3. Xem **Usage metrics**
4. Set **Quota alerts** để nhận thông báo

---

**Chúc bạn sử dụng tính năng Voice Control vui vẻ! 🎤🏠**
