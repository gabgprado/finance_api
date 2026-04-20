FactoryBot.define do
  factory :category do
    name { Faker::Commerce.department }
    category_type { 'expense' }
    color { '#FF5733' }
    user
  end
end
