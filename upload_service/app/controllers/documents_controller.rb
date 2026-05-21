class DocumentsController < ApplicationController
  def create
    document = Document.new(document_params)

    if document.save
      file_url = document.file.url(expires_in: 15.minutes)

      payload = {
        document_id: document.id,
        file_url: file_url,
        filename: document.file.filename.to_s
      }

      RabbitMqPublisher.publish("reports_queue", payload)

      render json: { message: "Upload realizado e enviado para processamento.", document_id: document.id }, status: :created
    else
      render json: { errors: document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    document = Document.find_by!(id: permitted_params[:document_id])

    file_url = document.file.url(expires_in: 15.minutes)

    render json: {
      document_id: document.id,
      file_url: file_url,
      filename: document.file.filename.to_s
    }
  end

  def index
    documents = Document.all

    render json: documents.map { |doc| { document_id: doc.id, title: doc.title } }
  end

  private

  def permitted_params
    params.permit(:title, :file, :document_id)
  end

  def document_params
    permitted_params.except(:document_id)
  end
end
