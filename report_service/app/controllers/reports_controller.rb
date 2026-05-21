class ReportsController < ApplicationController
  def index
    reports = Report.order(created_at: :desc)

    render json: reports, status: :ok
  end

  def show
    report = Report.find_by!(document_id: params[:document_id])
    pdf = PdfGenerator.call(report)

    if pdf.present?
      send_data pdf,
                filename:    "report_#{report.document_id}.pdf",
                type:        "application/pdf",
                disposition: "inline"
    else
      render json: { error: "Relatório ainda não está disponível para download" }, status: :ok
    end

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Relatório não encontrado para o document_id informado" }, status: :not_found
  end
end
