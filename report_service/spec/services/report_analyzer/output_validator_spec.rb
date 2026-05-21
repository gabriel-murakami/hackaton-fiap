require "rails_helper"

RSpec.describe ReportAnalyzer::OutputValidator do
  describe ".validate!" do
    let(:valid_json) do
      {
        "componentes" => [ "API Gateway", "Lambda" ],
        "descricao_arquitetura" => "Serverless architecture",
        "riscos" => [ "single point of failure" ],
        "boas_praticas" => [ "auto-scaling enabled" ],
        "recomendacoes" => [ "add monitoring" ],
        "confianca" => "alta"
      }.to_json
    end

    context "with valid JSON containing all required keys" do
      it "returns the parsed hash" do
        result = described_class.validate!(valid_json)
        expect(result).to be_a(Hash)
      end

      it "returns all expected fields" do
        result = described_class.validate!(valid_json)
        expect(result["confianca"]).to eq("alta")
        expect(result["descricao_arquitetura"]).to eq("Serverless architecture")
      end
    end

    context "with JSON missing required keys" do
      let(:incomplete_json) { { "componentes" => [ "API" ] }.to_json }

      it "raises an error listing the missing fields" do
        expect { described_class.validate!(incomplete_json) }.to raise_error(/Campos ausentes/)
      end
    end

    context "with an empty JSON object" do
      it "raises an error listing all missing fields" do
        expect { described_class.validate!("{}") }.to raise_error(/Campos ausentes/)
      end
    end

    context "with invalid JSON string" do
      it "raises an error about invalid response" do
        expect { described_class.validate!("not valid json") }.to raise_error("Resposta inválida (não é JSON)")
      end
    end

    context "with an empty string" do
      it "raises an error about invalid response" do
        expect { described_class.validate!("") }.to raise_error("Resposta inválida (não é JSON)")
      end
    end
  end
end
