module ReportAnalyzer
  class PromptBuilder
    def self.build
      <<~PROMPT
        Analise o diagrama de arquitetura fornecido.
        Você é um especialista em arquitetura de software.
        Não invente informações.
        Responda apenas com JSON válido.
        Não utilizar formatação de Markdown ou qualquer tipo de formatação de texto como negrito e itálico.

        TAREFAS:
        1. Identificar componentes arquiteturais
        2. Detectar possíveis riscos
        3. Avaliar boas práticas
        4. Sugerir melhorias

        FORMATO OBRIGATÓRIO:
        {
          "componentes": ["string"],
          "descricao_arquitetura": "string",
          "riscos": ["string"],
          "boas_praticas": ["string"],
          "recomendacoes": ["string"],
          "confianca": "alta | media | baixa"
        }
      PROMPT
    end
  end
end
