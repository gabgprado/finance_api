class ApplicationController < ActionController::API
  include AuthConcerns
  include RenderErrorsConcerns
  include QueryFilterConcern
  include ScopeStrategyConcern
  include TokenService
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  JSONAPI_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  before_action :select_serializer
  before_action :logged_in?
  before_action :authorized?
  before_action :enforce_jsonapi_content_type, if: :request_with_body?

  def enforce_jsonapi_content_type
    return if request.content_type == JSONAPI_CONTENT_TYPE

    render json: {
      errors: [{ status: '415', title: 'Unsupported Media Type',
                 detail: "Content-Type deve ser '#{JSONAPI_CONTENT_TYPE}'" }]
    }, status: :unsupported_media_type
  end

  def request_with_body?
    request.post? || request.put? || request.patch?
  end

  rescue_from ActiveRecord::RecordNotFound, with: :error_render_method

  serialization_scope :serializer_scope

  def serializer_scope
    {
      current_user:
    }
  end

  def authorized?
    if !current_user
      standard_error(status: :unauthorized,
                     error: { title: 'Autenticação requerida',
                              message: 'Para acessar este recurso é necessária a autenticação.' })

    elsif !current_user.ativo
      standard_error(status: :unauthorized,
                     error: { title: 'Usuário inativo',
                              message: 'Para acessar é necessário ativar o usuário.' })
    end
  end

  def public_data
    true
  end

  def select_serializer
    ActiveModel::Serializer.config.adapter = :json_api
  end

  def create_params(only = nil)
    if ActiveModel::Serializer.config.adapter == :json_api
      if only.nil?
        ActiveModelSerializers::Deserialization.jsonapi_parse(params)
      else
        ActiveModelSerializers::Deserialization.jsonapi_parse(params, only:)
      end
    elsif only.nil?
      params.permit!.to_h
    else
      params.permit(*only).to_h
    end
  end

  def standard_index(model, table_includes: [])
    render_api query_prepare(model, table_includes:), status: nil
  end

  def standard_show(object, table_includes: [], status: nil)
    render_api object, status:
  end

  def standard_create(object, table_includes: [])
    render_api object, status: :created
  end

  def error_render_method(exception)
    if exception.is_a? ActiveRecord::RecordNotFound
      standard_error(status: :not_found, error: { title: 'Registro não encontrado', message: exception.message })
    else
      standard_error(status: :internal_server_error,
                     error: { title: 'Erro inesperado',
                              message: exception.message })
    end
  end

  def render_json_api_msg_errors(title, detail, status = '400')
    render json: { errors: [{ status:, title:, detail: }] }, status:
  end

  def query_prepare(model, table_includes: [], pagination: true)
    object = model
    object = filter_to_where(model, filters) unless params[:filter].blank?
    object = scope(scope_filter, object, current_user&.id) if current_user
    object = scope(scope_filter, object, nil) unless current_user
    object = object.order(sorts)
    object = object.ordered if object.respond_to?(:ordered) && sorts.size.zero?
    object = object.includes(table_includes) unless table_includes.blank?
    pagination ? object.page(page[:number]).per_page(page[:size]) : object
  end

  def fields
    @fields ||= params[:fields]&.split(',')&.map(&:strip)
  end

  def sorts
    order = {}
    params[:sort].gsub(/\ +/, '').gsub(/[^A-z0-9\-_,]+/, '').split(',').each do |s|
      next order[s.split('-')[1].to_sym] = :desc if s.starts_with?('-')

      order[s.to_sym] = :asc
    end
    order
  rescue StandardError
    ''
  end

  def includes
    return '' unless params[:include]

    params[:include].gsub(/\ +/, '')
  end

  def scope_filter
    params[:scope] || params[:scopes] || params.dig(:filter, :scope_strategy)
  end

  def page
    pagination = params[:page] || {}
    pagination[:number] ||= 1
    pagination[:size] ||= 10
    pagination
  end

  def deve_paginar?(content)
    content.is_a?(ActiveRecord::Relation) && content.methods.include?(:current_page)
  end

  def filters
    return @filters ||= {} unless params[:filter]

    params.permit!
    @filters ||= QueryFilterConcern.settings_filters_operators(params[:filter])
  end

  def pagination_dict(collection)
    return unless collection.methods.include?(:current_page)

    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.previous_page,
      total_pages: collection.total_pages,
      total_count: collection.total_entries
    }
  end

  def pagination_dict_fixed(collection)
    {
      current_page: 1,
      next_page: nil,
      prev_page: nil,
      total_pages: 1,
      total_count: collection.length
    }
  end

  def render_api(content, status: :ok)
    params_render = { root: false }

    if deve_paginar?(content)
      pagination = pagination_dict(content)

      params_render[:root] = :data
      params_render[:meta] = pagination

      params_render[:adapter] = :json
    end

    params_render[:include] = includes
    params_render[:status] = status
    params_render[:json] = content
    params_render[:fields] = fields if fields

    render params_render
  end

  def render_api_generic(content, status: :ok)
    params_render = { root: false }

    pagination = pagination_dict_fixed(content)

    params_render[:meta] = pagination

    params_render[:adapter] = :json

    params_render[:include] = includes
    params_render[:status] = status
    params_render[:json] = { 'data': content, 'meta': pagination }
    params_render[:fields] = fields if fields

    render params_render
  end

  private

  def user_not_authorized
    render json: {
      errors: [{ status: '403', title: 'Acesso negado',
                 detail: 'Você não tem permissão para realizar esta ação.' }]
    }, status: :forbidden
  end
end
