# frozen_string_literal: true

# concerns/scope_strategy_concern.rb
module ScopeStrategyConcern
  extend ActiveSupport::Concern

  SCOPE_PATTERN = '\w*(?:\(.*?\)){,1}'

  def scope(scope_filter, model, usuario_id)
    return model unless scope_filter

    @usuario_id = usuario_id

    scopes = clean_scopes(scope_filter)

    translate_scopes_to_model(scopes, model)
  end

  def treat_scope(scope)
    @my_user_param = {}
    @my_user_param[:usuario_id] = @usuario_id if check_my(scope) && @usuario_id

    method_params = scope.scan(/(.*)\((.*)\)/)
    retorno = [method_params.first ? method_params.first.first : scope]
    retorno += method_params.first[1].split(/ *, */) unless method_params.empty?

    retorno
  end

  def check_my(scope)
    prefixs = %w[meus minhas]

    prefixs.map do |prefix|
      (scope.start_with?("#{prefix}_") || scope == prefix)
    end&.select { |check| check }&.count&.positive?
  end

  def clean_scopes(scopes)
    scopes.split(/(#{SCOPE_PATTERN})/)
          .reject { |term| term.strip.empty? }
          .map { |term| term.gsub(/^(?:[Oo][Rr]|\\|\\|)$/, 'OR').gsub(/^(?:[Aa][Nn][Dd]|&&|,)$/, 'AND') }
  end

  def ignore_scopes(scopes)
    @scope_ignore = Array.wrap(scopes)
  end

  def translate_scopes_to_model(scopes, model)
    scopes.each do |term|
      if term =~ /(OR|AND)/
        @condition = term unless @ignore_next_condition
        next @ignore_next_condition = nil
      end
      next if (@ignore_next_condition = @scope_ignore&.include?(term))

      treated_scope = treat_scope(term)
      unless model.external_scopes.include? treated_scope.first
        throw StandardError.new "scope_strategy não encontrado: #{term}"
      end

      model = if @condition == 'OR'
                model_assist = model.name.constantize
                model.or(model_assist.send(*treated_scope, **@my_user_param))
              else
                model.send(*treated_scope, **@my_user_param)
              end

      @condition = nil
    end
    model
  end
end