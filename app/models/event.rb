class Event < ApplicationRecord
  has_many :comments, dependent: :destroy

  validates :title, :location, :starts_at, presence: true
end
