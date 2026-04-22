class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :category

  TRANSACTION_TYPES = %w[income expense transfer].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES }
  validates :date, presence: true
  validates :account_id, :category_id, :user_id, presence: true

  validate :category_and_account_belong_to_user
  validate :category_type_matches_transaction_type

  after_create :update_account_balance
  after_destroy :revert_account_balance
  before_update :revert_and_reapply_balance

  default_scope -> { order(created_at: :desc) }

  # Scopes for filtering
  scope :by_period, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_category, ->(id) { where(category_id: id) }
  scope :by_account, ->(id) { where(account_id: id) }
  scope :by_type, ->(type) { where(transaction_type: type) }
  scope :ordered, -> { order(date: :desc, created_at: :desc) }

  private

  def category_and_account_belong_to_user
    if account && account.user_id != user_id
      errors.add(:account_id, 'must belong to the same user')
    end

    if category && category.user_id != user_id
      errors.add(:category_id, 'must belong to the same user')
    end
  end

  def category_type_matches_transaction_type
    return unless category

    valid_types = {
      'income' => 'income',
      'expense' => 'expense',
      'transfer' => 'expense'
    }

    if category.category_type != valid_types[transaction_type]
      errors.add(:category, "type must be #{valid_types[transaction_type]} for #{transaction_type} transactions")
    end
  end

  def update_account_balance
    case transaction_type
    when 'income'
      account.update!(balance: account.balance + amount)
    when 'expense', 'transfer'
      account.update!(balance: account.balance - amount)
    end
  end

  def revert_account_balance
    case transaction_type
    when 'income'
      account.update!(balance: account.balance - amount)
    when 'expense', 'transfer'
      account.update!(balance: account.balance + amount)
    end
  end

  def revert_and_reapply_balance
    return unless amount_changed? || transaction_type_changed?

    # Revert the previous balance impact
    old_amount = amount_was
    old_type = transaction_type_was

    case old_type
    when 'income'
      account.update!(balance: account.balance - old_amount)
    when 'expense', 'transfer'
      account.update!(balance: account.balance + old_amount)
    end

    # Apply the new balance impact
    case transaction_type
    when 'income'
      account.update!(balance: account.balance + amount)
    when 'expense', 'transfer'
      account.update!(balance: account.balance - amount)
    end
  end
end
