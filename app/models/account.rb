class Account < ApplicationRecord
  belongs_to :user

  ACCOUNT_TYPES = %w[checking savings credit investment].freeze

  validates :name, presence: true
  validates :account_type, inclusion: { in: ACCOUNT_TYPES }
  validates :currency, presence: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }, unless: :credit_account?
  validates :balance, numericality: true, if: :credit_account?

  default_scope -> { order(created_at: :desc) }

  private

  def credit_account?
    account_type == 'credit'
  end
end
