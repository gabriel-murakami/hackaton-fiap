class ReportsController < ApplicationController
  def index
    reports = Report.order(created_at: :desc)

    render json: reports, status: :ok
  end

  def show
    report = Report.find_by!(document_id: params[:document_id])

    render json: report, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Relatório não encontrado para o document_id informado" }, status: :not_found
  end
end
