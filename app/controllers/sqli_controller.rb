class SqliController < ApplicationController
  # Demo Classic SQLi - Bypass login
  def classic_demo
    render :classic_demo
  end

  # Demo Error-based SQLi với raw connection để show lỗi rõ hơn
  def error_raw_demo
    user_id = params[:user_id]
    @raw_error = nil
    @sql_query = nil

    if user_id.present?
      @sql_query = "SELECT * FROM users WHERE id = #{user_id}"

      begin
        # Sử dụng raw connection để lấy lỗi chi tiết
        connection = ActiveRecord::Base.connection
        result = connection.execute(@sql_query)

        @users = []
        result.each do |row|
          @users << OpenStruct.new(row) if row.is_a?(Hash)
        end

        flash[:success] =
          "Query executed successfully. Found #{@users.count} record(s)"
      rescue StandardError => e
        @raw_error = {
          class: e.class.name,
          message: e.message,
          sql_state: e.respond_to?(:sql_state) ? e.sql_state : "N/A",
          error_number: e.respond_to?(:error_number) ? e.error_number : "N/A"
        }
        flash[:error] = "Raw SQL Error detected!"
      end
    end

    render :error_raw_demo
  end

  # Demo Error-based SQLi
  def error_based_demo
    user_id = params[:user_id]
    @error_details = nil
    @sql_query = nil

    if user_id.present?
      begin
        # Query vulnerable cho error-based SQLi
        # expl: 1 AND (SELECT @@version) -> MySQL version
        @sql_query = "SELECT * FROM users WHERE id = #{user_id}"
        @users = User.find_by_sql(@sql_query)

        if @users.empty?
          flash[:info] = "No user found with ID: #{user_id}"
        else
          flash[:success] = "Found #{@users.count} user(s)"
        end
      rescue StandardError => e
        @error_details = {
          message: e.message,
          backtrace: e.backtrace&.first(3),
          sql_state: e.respond_to?(:sql_state) ? e.sql_state : "N/A",
          error_number: e.respond_to?(:error_number) ? e.error_number : "N/A"
        }
        flash[:error] = "SQL Error: #{e.message}"
      end
    end

    render :error_based_demo
  end

  # Demo Union-based SQLi
  def union_demo
    search_term = params[:search]

    if search_term.present?
      begin
        # Query vulnerable cho Union-based SQLi
        # expl: ' UNION SELECT id, email, password_digest FROM users --
        sql = "SELECT id, title, description FROM events WHERE title LIKE '%#{search_term}%'"
        @events = Event.find_by_sql(sql)

        flash[:info] =
          "Found #{@events.count} event(s) matching '#{search_term}'"
      rescue StandardError => e
        flash[:error] = "Search Error: #{e.message}"
      end
    end

    render :union_demo
  end

  # Demo Blind SQLi
  def blind_demo
    email = params[:email]

    if email.present?
      begin
        # Query vulnerable cho Blind SQLi
        # expl: admin@test.com' AND LENGTH(database())=20--
        sql = "SELECT COUNT(*) as count FROM users WHERE email='#{email}'"
        result = User.find_by_sql(sql).first

        @exists = result.count > 0
        flash[:info] = "Email check completed for: #{email}"
      rescue StandardError => e
        flash[:error] = "Check failed: #{e.message}"
        @exists = false
      end
    end

    render :blind_demo
  end

  # Demo Time-based Blind SQLi
  def time_based_demo
    email = params[:email]

    if email.present?
      start_time = Time.current

      begin
        sql = "SELECT email FROM users WHERE email='#{email}' LIMIT 1"
        result = User.find_by_sql(sql)

        @response_time = ((Time.current - start_time) * 1000).round(2)
        @found = result.any?

        flash[:info] = "Time-based check completed in #{@response_time}ms"
      rescue StandardError => e
        @response_time = ((Time.current - start_time) * 1000).round(2)
        flash[:error] = "Error after #{@response_time}ms: #{e.message}"
      end
    end

    render :time_based_demo
  end
end
