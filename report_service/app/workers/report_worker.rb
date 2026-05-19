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

      begin
        file_content = URI.open(file_url).read
        Rails.logger.info "Arquivo baixado com sucesso via URL do MinIO."

        prompt = "Atue como um analista especialista. Analise o arquivo anexo e extraia os principais pontos textuais estruturados em formato de topicos normatizados."

        # ai_result = ReportAnalyzerService.analyze_file(file_content, data["filename"], prompt)
        ai_result = "TESTE DO FLUXO"

        if ai_result
          Rails.logger.info "--- RESPOSTA DO GEMINI RECEBIDA COM SUCESSO ---"
          Rails.logger.info "\n#{ai_result}"
          Rails.logger.info "----------------------------------------------"

          Report.create!(
            document_id: data["document_id"],
            result: ai_result
          )
        else
          Rails.logger.error "Nao foi possivel obter o retorno do Gemini."
        end

        ack!
      rescue OpenURI::HTTPError => e
        Rails.logger.error "Falha ao baixar o arquivo da URL. Erro HTTP: #{e.message}"
        reject!
      rescue StandardError => e
        Rails.logger.fatal "Erro inesperado no processamento do worker: #{e.class} - #{e.message}"
        Rails.logger.fatal e.backtrace.join("\n")
        reject!
      end
    end
  end
end
