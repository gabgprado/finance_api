class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :color, :icon_name, :category_type, :created_at
end
