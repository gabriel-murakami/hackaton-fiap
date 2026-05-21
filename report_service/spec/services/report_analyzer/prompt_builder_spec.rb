require "rails_helper"

RSpec.describe ReportAnalyzer::PromptBuilder do
  describe ".build" do
    subject(:prompt) { described_class.build }

    it "returns a string" do
      expect(prompt).to be_a(String)
    end

    it "instructs the AI to respond only with valid JSON" do
      expect(prompt).to include("JSON válido")
    end

    it "includes the required output keys in the format example" do
      expect(prompt).to include("componentes")
      expect(prompt).to include("descricao_arquitetura")
      expect(prompt).to include("riscos")
      expect(prompt).to include("boas_praticas")
      expect(prompt).to include("recomendacoes")
      expect(prompt).to include("confianca")
    end

    it "lists the expected analysis tasks" do
      expect(prompt).to include("Identificar componentes arquiteturais")
      expect(prompt).to include("Detectar possíveis riscos")
      expect(prompt).to include("Avaliar boas práticas")
      expect(prompt).to include("Sugerir melhorias")
    end
  end
end
