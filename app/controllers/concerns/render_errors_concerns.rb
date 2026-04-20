module RenderErrorsConcerns
  extend ActiveSupport::Concern

  def standard_error(error: nil, errors: [], status: :bad_request)
    # errors = [] if errors.nil?
    errors = format_model_errors(errors) if errors.is_a? ActiveModel::Errors
    errors << error if error && !error.empty?

    render json: { status: Rack::Utils.status_code(status), errors: }, status:
  end

  def format_model_errors(model_errors)
    return unless model_errors

    model_errors.full_messages.map do |message|
      { title: 'Validação no modelo de dados', message: }
    end
  end
end