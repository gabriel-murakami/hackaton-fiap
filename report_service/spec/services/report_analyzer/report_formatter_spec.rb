require "rails_helper"

RSpec.describe ReportAnalyzer::ReportFormatter do
  describe ".format" do
    let(:data) do
      {
        "descricao_arquitetura" => "Microservices with API Gateway",
        "riscos" => [ "vendor lock-in", "network latency" ],
        "recomendacoes" => [ "add circuit breaker", "implement retry logic" ],
        "confianca" => "alta"
      }
    end

    subject(:result) { described_class.format(data) }

    it "returns the architecture description as summary" do
      expect(result[:summary]).to eq("Microservices with API Gateway")
    end

    it "returns the risks list" do
      expect(result[:risks]).to eq([ "vendor lock-in", "network latency" ])
    end

    it "returns the recommendations list" do
      expect(result[:recommendations]).to eq([ "add circuit breaker", "implement retry logic" ])
    end

    it "returns the confidence level" do
      expect(result[:confidence]).to eq("alta")
    end

    it "includes a generated_at timestamp" do
      expect(result[:generated_at]).to be_a(ActiveSupport::TimeWithZone)
    end
  end
end
