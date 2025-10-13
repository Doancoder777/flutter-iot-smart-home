# 📖 Hướng Dẫn Sử Dụng Tự Động Hóa

## ✨ Tính Năng Mới - Dễ Dàng Hơn!

### 🎯 **Thêm Quy Tắc**
1. Bấm nút **➕ Thêm quy tắc**
2. Nhập tên quy tắc (VD: "Tưới cây tự động")
3. Chọn điều kiện (tùy chọn):
   - Chọn cảm biến (nhiệt độ, độ ẩm, etc.)
   - Chọn toán tử (>, <, ==, etc.)
   - Nhập giá trị
   - **HOẶC** bỏ chọn "Không dùng cảm biến"
4. Chọn hành động:
   - Chọn thiết bị
   - Chọn hành động (Bật/Tắt hoặc góc servo)
5. (Tùy chọn) Chọn **Kích hoạt theo thời gian**:
   - Chọn giờ bắt đầu
   - Chọn giờ kết thúc
6. Bấm **Lưu**

### ✏️ **Chỉnh Sửa Quy Tắc** - 3 CÁCH!

**Cách 1: Menu nhanh**
- Bấm vào nút **⋮** (3 chấm) trên card quy tắc
- Chọn "Chỉnh sửa"

**Cách 2: Từ chi tiết**
- Bấm vào card quy tắc để xem chi tiết
- Bấm nút **"Chỉnh sửa"** ở dưới

**Cách 3: Swipe (chỉ xem)**
- Vuốt card sang trái để xem nút xóa

### 🗑️ **Xóa Quy Tắc** - 2 CÁCH!

**Cách 1: Swipe to delete**
- Vuốt card quy tắc sang **TRÁI** ←
- Xác nhận xóa trong dialog

**Cách 2: Menu**
- Bấm nút **⋮** trên card
- Chọn "Xóa" (màu đỏ)
- Xác nhận

### 👁️ **Xem Chi Tiết**
- Bấm vào card quy tắc
- Hoặc menu **⋮** → "Chi tiết"

### 🔄 **Bật/Tắt Quy Tắc**
- Toggle switch trên mỗi card
- Quy tắc tắt = không chạy tự động

---

## 💡 Ví Dụ Thực Tế

### 1️⃣ **Tưới Cây Khi Đất Khô**
- Tên: "Tưới cây tự động"
- Điều kiện: Độ ẩm đất < 30
- Hành động: Máy bơm → Bật
- Thời gian: 06:00 - 18:00

### 2️⃣ **Bật Đèn Khi Tối**
- Tên: "Đèn tối tự động"
- Điều kiện: Ánh sáng < 20
- Hành động: Đèn phòng khách → Bật
- Thời gian: 18:00 - 06:00

### 3️⃣ **Đóng Mái Khi Mưa**
- Tên: "Đóng mái khi mưa"
- Điều kiện: Mưa > 50
- Hành động: Mái che → Góc 0°

### 4️⃣ **Bật Quạt Theo Giờ (Không Dùng Cảm Biến)**
- Tên: "Quạt buổi trưa"
- Điều kiện: ✅ Không dùng cảm biến
- Hành động: Máy ion hóa → Bật
- Thời gian: 12:00 - 14:00

---

## ⚙️ Cách Hoạt Động

### 🔍 Kiểm Tra Tự Động
- Hệ thống kiểm tra điều kiện **mỗi 5 giây**
- Nếu điều kiện đúng → thực thi hành động
- Cooldown **30 giây** tránh spam

### 📊 Ưu Tiên
1. ✅ Quy tắc đang BẬT
2. ⏰ Trong khung thời gian (nếu có)
3. 🎯 Điều kiện cảm biến đúng (nếu có)

### 🚀 Thực Thi
- Gửi lệnh qua MQTT tự động
- Hiển thị log: `🎬 Automation: Turn ON pump`
- Lưu thời gian chạy cuối

---

## 🎨 Giao Diện

### Card Quy Tắc
```
┌─────────────────────────────────────┐
│ ✓ Tên quy tắc              [ON] ⋮  │
│   2 điều kiện • 1 hành động         │
│                                     │
│ 📅 Lần chạy cuối: 2 phút trước      │
└─────────────────────────────────────┘
```

### Màu Sắc
- 🟢 **Xanh**: Đang bật
- ⚪ **Xám**: Đã tắt
- 🔵 **Xanh dương**: Thông tin
- 🔴 **Đỏ**: Xóa

---

## 🛠️ Khắc Phục Sự Cố

### ❌ Quy tắc không chạy?
1. Kiểm tra quy tắc có **BẬT** không
2. Kiểm tra **thời gian** hoạt động (nếu có)
3. Kiểm tra **điều kiện** cảm biến
4. Xem log console: `✅ AutomationService: Initialized`

### ❌ Không thể chỉnh sửa?
1. Bấm nút **⋮** → "Chỉnh sửa"
2. Hoặc bấm vào card → "Chỉnh sửa"

### ❌ Xóa không được?
1. Vuốt **SANG TRÁI** ←
2. Hoặc menu **⋮** → "Xóa"

---

## 📝 Tips & Tricks

✅ **Sử dụng tên rõ ràng**: "Tưới cây buổi sáng" thay vì "Rule 1"

✅ **Kết hợp điều kiện + thời gian**: Tưới cây khi đất khô VÀ từ 6h-18h

✅ **Tắt quy tắc tạm thời**: Dùng switch thay vì xóa

✅ **Kiểm tra log**: Xem console để debug

✅ **Cooldown 30s**: Quy tắc không chạy liên tục ngay cả khi điều kiện đúng

---

## 🔐 Lưu Ý Quan Trọng

⚠️ **Quy tắc tự động chạy ngầm** - không cần mở app

⚠️ **Kiểm tra kỹ điều kiện** trước khi bật

⚠️ **Thời gian áp dụng hàng ngày** - không phải 1 lần

⚠️ **Cooldown 30s** - tránh spam thiết bị

---

Made with ❤️ by Automation Team
