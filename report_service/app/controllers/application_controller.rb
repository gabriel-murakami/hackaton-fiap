class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordInvalid do |e|
    render_and_log_error(:unprocessable_entity, e.message, e.record.class.name)
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_and_log_error(:not_found, e.message)
  end

  private

  def render_and_log_error(status, message, resource = nil)
    Rails.logger.info(error: message, status: status, resource: resource)
    render json: { message: message }, status: status
  end
end
