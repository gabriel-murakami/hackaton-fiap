module ReportAnalyzer
  class ReportFormatter
    def self.format(data)
      {
        summary: data["descricao_arquitetura"],
        risks: data["riscos"],
        recommendations: data["recomendacoes"],
        confidence: data["confianca"],
        generated_at: Time.current
      }
    end
  end
end
