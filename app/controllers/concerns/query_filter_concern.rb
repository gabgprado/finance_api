# concerns/query_filter_concern.rb
module QueryFilterConcern
  extend ActiveSupport::Concern

  def filter_to_where(model, filter)
    table = model.arel_table

    filter&.each do |key, value|
      next if ignore_filter_list.include?(key.to_s)

      value.each do |operator, operator_value|
        operator_value = nil if operator_value == 'null'

        if association?(key.to_s)
          split_key = key.to_s.split('.')
          association = association(model, split_key.first)
          break unless association

          query = operator_value(association.klass.arel_table, split_key.second.to_sym, operator, operator_value)
          model = model.joins(association.name.to_sym)
        end
        query ||= operator_value(table, key.to_sym, operator, operator_value)

        next model = model.where.not(query) if %w[nin not_in].include?(operator)

        model = model.where(query)
      end
    end
    model
  end

  def operator_value(table, field, operator, value)
    operator = operator.to_s
    return table[field].eq(value) if operator == 'eq'
    return table[field].not_eq(value) if operator == 'neq'
    return table[field].lt(value) if operator == 'lt'
    return table[field].gt(value) if operator == 'gt'
    return table[field].lteq(value) if operator == 'lte'
    return table[field].gteq(value) if operator == 'gte'

    in_values = value.gsub(/ , */, ',').split(',')
    return table[field].in(in_values) if %w[nin not_in in].include?(operator) && in_values.size.positive?

    ["unaccent(#{table.name}.#{field}) ILIKE unaccent(?)", "%#{value.gsub(/ +/, '%')}%"] if %w[ilike like
                                                                                               contain].include?(operator)
    # return table[field].matches("%#{value.gsub(/[ ]+/, '%')}%") if %w[ilike like contain].include?(operator)
  end

  def association?(key)
    key.split('.').size > 1
  end

  def association(model, relation)
    possible_names = [relation.pluralize.to_sym, relation.singularize.to_sym]
    model.reflect_on_all_associations.find { |a| possible_names.include? a.name }
  end

  def self.settings_filters_operators(filters)
    filters = filters&.to_h
    filters&.each do |key, value|
      next if value.is_a? Hash

      filters[key] = { eq: value }
    end
    filters
  end

  def ignore_filter_list
    %w[scope_stratege scope_strategy]
  end

  class Impl
    include QueryFilterConcern
  end
end