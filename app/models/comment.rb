class Comment < ApplicationRecord
  # Sử dụng gem như sanitize để loại bỏ các thẻ HTML nguy hiểm như <Script>
  # before_save :sanitize_content

  belongs_to :event
  belongs_to :user
  validates :content, presence: true, length: {maximum: 2000}

  # private
  # def sanitize_content
  #   self.content = Sanitize.fragment(content, Sanitize::Config::RESTRICTED)
  # end
end
