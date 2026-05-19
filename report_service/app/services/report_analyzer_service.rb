class ReportAnalyzerService
  def self.analyze_file(file_content, filename, prompt_command)
    require "google/genai"

    timestamp = Time.now.utc.iso8601

    # Inicializa o cliente. Ele busca automaticamente a ENV['GEMINI_API_KEY']
    client = Google::GenAI::Client.new

    mime_type = case File.extname(filename).downcase
    when ".pdf"  then "application/pdf"
    when ".png"  then "image/png"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".csv"  then "text/csv"
    when ".txt"  then "text/plain"
    else "application/octet-stream"
    end

    Rails.logger.info "[ReportAnalyzerService] Enviando payload multimodal para o Gemini (Modelo: gemini-2.5-flash)"

    response = client.models.generate_content(
      model: "gemini-2.5-flash",
      contents: [
        prompt_command,
        {
          inline_data: {
            data: Base64.strict_encode64(file_content),
            mime_type: mime_type
          }
        }
      ]
    )

    response.text
  rescue StandardError => e
    Rails.logger.error "[ReportAnalyzerService] Erro na integracao com a API do Gemini: #{e.class} - #{e.message}"
    nil
  end
end
