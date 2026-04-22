class User < ApplicationRecord
  has_secure_password

  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :transactions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  after_create :create_default_categories

  private

  def create_default_categories
    categories.create!([
      { name: 'Salário', category_type: 'income', color: '#2ECC71' },
      { name: 'Alimentação', category_type: 'expense', color: '#E74C3C' },
      { name: 'Transporte', category_type: 'expense', color: '#3498DB' },
      { name: 'Moradia', category_type: 'expense', color: '#F1C40F' },
      { name: 'Lazer', category_type: 'expense', color: '#9B59B6' },
      { name: 'Saúde', category_type: 'expense', color: '#1ABC9C' }
    ])
  end
end
