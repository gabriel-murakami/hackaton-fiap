require "net/http"
require "json"
require "base64"

module ReportAnalyzer
  class AiClient
    API_URL = ENV["GEMINI_API_URL"]

    def self.analyze(content:, prompt:)
      uri = URI("#{API_URL}?key=#{ENV['GEMINI_API_KEY']}")

      body = build_body(content: content, prompt: prompt)

      response = Net::HTTP.post(
        uri,
        body.to_json,
        "Content-Type" => "application/json"
      )

      Rails.logger.info("Resposta recebida da API Gemini")

      parsed = JSON.parse(response.body)

      extract_text(parsed)
    end

    def self.build_body(content:, prompt:)
      case content[:type]

      when :text
        {
          contents: [
            {
              parts: [
                { text: "#{prompt}\n\n#{content[:content]}" }
              ]
            }
          ]
        }

      when :image
        {
          contents: [
            {
              parts: [
                { text: "#{prompt}" },
                {
                  inline_data: {
                    mime_type: "image/png",
                    data: Base64.strict_encode64(content[:content])
                  }
                }
              ]
            }
          ]
        }

      else
        raise "Tipo inválido"
      end
    end

    def self.extract_text(response)
      raw_text = response.dig("candidates", 0, "content", "parts", 0, "text")

      return nil unless raw_text

      clean_json = raw_text.gsub(/```json\n?/i, "").gsub(/```/, "").strip

      clean_json
    end
  end
end
