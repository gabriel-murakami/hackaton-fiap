module ReportAnalyzer
  class ReportFormatter
    def self.format(data)
      {
        summary: data["descricao_arquitetura"],
        risks: data["riscos"],
        recommendations: data["recomendacoes"],
        best_practices: data["boas_praticas"],
        confidence: data["confianca"],
        components: data["componentes"],
        generated_at: Time.current
      }
    end
  end
end
