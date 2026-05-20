require "open-uri"
require "net/http"

class ReportWorker
  include Sneakers::Worker
  from_queue "reports_queue", env: nil

  def work(raw_post)
    data = JSON.parse(raw_post)
    file_url = data["file_url"]

    Rails.logger.tagged("ReportWorker", "Doc-ID: #{data['document_id']}") do
      Rails.logger.info "Iniciando processamento do arquivo: #{data['filename']}"

      new_report = Report.new(
        document_id: data["document_id"],
        document_name: data["filename"],
        status: :pending
      )

      begin
        file_content = URI.open(file_url).read
        Rails.logger.info "Arquivo baixado com sucesso via URL do MinIO."

        ai_result = ReportAnalyzer::Orchestrator.call(
          file: file_content, filename: data["filename"], report: new_report
        )

        if ai_result
          Rails.logger.info "Análise concluída com sucesso"

          new_report.update(
            status: :completed,
            result: ai_result
          )
        else
          Rails.logger.error "Nao foi possivel obter o retorno"
        end

        ack!
      rescue OpenURI::HTTPError => e
        Rails.logger.error "Falha ao baixar o arquivo da URL. Erro HTTP: #{e.message}"

        new_report.failed!

        reject!
      rescue StandardError => e
        Rails.logger.fatal "Erro inesperado no processamento do worker: #{e.class} - #{e.message}"
        Rails.logger.fatal e.backtrace.join("\n")

        new_report.failed!

        reject!
      end
    end
  end
end
