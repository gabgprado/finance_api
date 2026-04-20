FactoryBot.define do
  factory :account do
    name { Faker::Bank.name }
    account_type { 'checking' }
    balance { 1000.0 }
    currency { 'BRL' }
    user
  end
end
