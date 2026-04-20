# config/initializers/mime_types.rb
Mime::Type.register "application/vnd.api+json", :jsonapi

# config/initializers/jsonapi_renderer.rb or similar
ActionDispatch::Request.parameter_parsers[:jsonapi] = -> (body) { 
  data = ActiveSupport::JSON.decode(body)
  data.is_a?(Hash) ? data : { _json: data }
}
