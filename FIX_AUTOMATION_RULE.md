# 🔧 SỬA AUTOMATION RULE TRONG FIRESTORE

## ❌ Vấn đề hiện tại:

Rule `"batdenwc"` đang có condition:
```
Chuyển động == true (== 1)
→ Tắt đèn
```

**Kết quả**: Khi phát hiện chuyển động → Tắt đèn (NGƯỢC!)

---

## ✅ Giải pháp:

### **Cách 1: Sửa trong Firebase Console (NHANH NHẤT)**

1. Mở Firebase Console
2. Vào **Firestore Database**
3. Tìm collection: `users/{userId}/automation_rules`
4. Tìm document có `name: "batdenwc"`
5. **Sửa field `conditions`**:
   ```json
   {
     "sensorId": "sensor_1762005354206",
     "operator": "==",
     "value": 0  ← ĐỔI TỪ 1 SANG 0
   }
   ```
6. **Save**

---

### **Cách 2: Xóa và tạo lại trong app**

1. Vào **Automation** screen
2. **Xóa** rule `"batdenwc"`
3. **Tạo rule mới**:
   - Name: `batdenwc`
   - Condition:
     - Sensor: Chuyển động
     - Operator: `==`
     - Value: `0` ✅ (Không phát hiện)
   - Action: Turn OFF đèn

---

## 📊 Logic sau khi sửa:

| Tình huống | Arduino gửi | App nhận | Rule check | Kết quả |
|---|---|---|---|---|
| Tay vào (phát hiện) | `1` | `true` | `true == 0` → FALSE | Đèn SÁNG ✅ |
| Tay ra (không phát hiện) | `0` | `false` | `false == 0` → TRUE | Đèn TẮT ✅ |

---

## 🎯 Kết luận:

**KHÔNG CẦN SỬA CODE** - Chỉ cần **đổi value trong automation condition từ 1 sang 0**!

