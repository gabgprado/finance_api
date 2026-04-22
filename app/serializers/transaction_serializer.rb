class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :amount, :description, :transaction_type, :date, :created_at

  has_one :account
  has_one :category
  has_one :user
end

class TransactionAccountSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class TransactionCategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :color
end

class TransactionUserSerializer < ActiveModel::Serializer
  attributes :id, :email
end
