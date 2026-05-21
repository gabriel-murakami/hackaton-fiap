require "rails_helper"

RSpec.describe ReportAnalyzer::Orchestrator do
  let(:report) { build(:report) }
  let(:file) { "binary file content" }
  let(:filename) { "architecture.pdf" }

  let(:processed_input) { { type: :text, content: "extracted architecture text" } }

  let(:ai_response) do
    {
      "componentes" => [ "API Gateway", "Lambda" ],
      "descricao_arquitetura" => "Serverless architecture",
      "riscos" => [ "cold start latency" ],
      "boas_praticas" => [ "auto-scaling" ],
      "recomendacoes" => [ "add monitoring" ],
      "confianca" => "alta"
    }.to_json
  end

  let(:validated_data) { JSON.parse(ai_response) }

  let(:formatted_result) do
    {
      summary: "Serverless architecture",
      risks: [ "cold start latency" ],
      recommendations: [ "add monitoring" ],
      confidence: "alta",
      generated_at: Time.current
    }
  end

  before do
    allow(ReportAnalyzer::FileProcessor).to receive(:validate!)
    allow(ReportAnalyzer::FileProcessor).to receive(:process).and_return(processed_input)
    allow(ReportAnalyzer::AiClient).to receive(:analyze).and_return(ai_response)
    allow(ReportAnalyzer::OutputValidator).to receive(:validate!).and_return(validated_data)
    allow(ReportAnalyzer::ReportFormatter).to receive(:format).and_return(formatted_result)
  end

  describe ".call" do
    it "validates the file before processing" do
      expect(ReportAnalyzer::FileProcessor).to receive(:validate!).with(file, filename)
      described_class.call(file: file, filename: filename, report: report)
    end

    it "transitions the report to processing status" do
      described_class.call(file: file, filename: filename, report: report)
      expect(report.status).to eq("processing")
    end

    it "processes the file to extract content" do
      expect(ReportAnalyzer::FileProcessor).to receive(:process).with(file, filename)
      described_class.call(file: file, filename: filename, report: report)
    end

    it "calls AiClient with the processed input and the built prompt" do
      expected_prompt = ReportAnalyzer::PromptBuilder.build
      expect(ReportAnalyzer::AiClient).to receive(:analyze).with(
        content: processed_input,
        prompt: expected_prompt
      )
      described_class.call(file: file, filename: filename, report: report)
    end

    it "validates the AI output" do
      expect(ReportAnalyzer::OutputValidator).to receive(:validate!).with(ai_response)
      described_class.call(file: file, filename: filename, report: report)
    end

    it "formats the validated data" do
      expect(ReportAnalyzer::ReportFormatter).to receive(:format).with(validated_data)
      described_class.call(file: file, filename: filename, report: report)
    end

    it "returns the formatted result" do
      result = described_class.call(file: file, filename: filename, report: report)
      expect(result).to eq(formatted_result)
    end

    context "when file validation fails" do
      before do
        allow(ReportAnalyzer::FileProcessor).to receive(:validate!).and_raise("Formato não suportado")
      end

      it "raises the validation error" do
        expect {
          described_class.call(file: file, filename: filename, report: report)
        }.to raise_error("Formato não suportado")
      end

      it "does not transition the report to processing" do
        begin
          described_class.call(file: file, filename: filename, report: report)
        rescue RuntimeError
          nil
        end
        expect(report.status).not_to eq("processing")
      end
    end

    context "when the AI client raises an error" do
      before do
        allow(ReportAnalyzer::AiClient).to receive(:analyze).and_raise("API unavailable")
      end

      it "propagates the error" do
        expect {
          described_class.call(file: file, filename: filename, report: report)
        }.to raise_error("API unavailable")
      end
    end

    context "when output validation fails" do
      before do
        allow(ReportAnalyzer::OutputValidator).to receive(:validate!).and_raise("Resposta inválida (não é JSON)")
      end

      it "propagates the validation error" do
        expect {
          described_class.call(file: file, filename: filename, report: report)
        }.to raise_error("Resposta inválida (não é JSON)")
      end
    end
  end
end
