module ReportAnalyzer
  class OutputValidator
    REQUIRED_KEYS = %w[
      componentes
      descricao_arquitetura
      riscos
      boas_praticas
      recomendacoes
      confianca
    ]

    def self.validate!(raw_output)
      json = JSON.parse(raw_output)

      missing = REQUIRED_KEYS - json.keys
      raise "Campos ausentes: #{missing.join(", ")}" if missing.any?

      json
    rescue JSON::ParserError
      raise "Resposta inválida (não é JSON)"
    end
  end
end
