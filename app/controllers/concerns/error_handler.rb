module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActionController::ParameterMissing, with: :parameter_missing
  end

  private

  def record_not_found(exception)
    resource_name = exception.model.downcase
    render json: { 
      error: "#{resource_name.capitalize} not found",
      details: exception.message 
    }, status: :not_found
  end

  def parameter_missing(exception)
    render json: { 
      error: "Missing required parameter",
      details: exception.message 
    }, status: :bad_request
  end

  def render_error(message, status = :unprocessable_entity, details = nil)
    response = { error: message }
    response[:details] = details if details
    render json: response, status: status
  end

  def render_validation_errors(record)
    render json: { 
      error: "Validation failed",
      errors: record.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
