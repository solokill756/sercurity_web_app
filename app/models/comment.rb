class Comment < ApplicationRecord
  belongs_to :event
  belongs_to :user
  validates :content, presence: true, length: { maximum: 2000 }
end
