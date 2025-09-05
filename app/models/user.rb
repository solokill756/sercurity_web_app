class User < ApplicationRecord
  has_secure_password

  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validates :role, inclusion: { in: %w[user admin] }
end
