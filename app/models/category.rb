class Category < ApplicationRecord
  belongs_to :user

  CATEGORY_TYPES = %w[income expense].freeze

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :category_type, inclusion: { in: CATEGORY_TYPES }
  validates :color, format: { with: /\A#\h{6}\z/ }, allow_blank: true

  default_scope -> { order(created_at: :desc) }
end
