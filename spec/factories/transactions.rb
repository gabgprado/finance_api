FactoryBot.define do
  factory :transaction do
    amount { Faker::Number.decimal(l_digits: 4, r_digits: 2).abs }
    description { Faker::Commerce.sentence }
    transaction_type { 'expense' }
    date { Time.current.to_date }
    user
    account { association :account, user: user }
    category { association :category, user: user, category_type: 'expense' }

    trait :income do
      transaction_type { 'income' }
      category { association :category, user: user, category_type: 'income' }
    end

    trait :expense do
      transaction_type { 'expense' }
      category { association :category, user: user, category_type: 'expense' }
    end

    trait :transfer do
      transaction_type { 'transfer' }
      category { association :category, user: user, category_type: 'expense' }
    end
  end
end
