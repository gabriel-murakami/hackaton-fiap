require "rails_helper"

RSpec.describe PdfGenerator do
  let(:result) do
    {
      "summary"         => "Arquitetura baseada em microsserviços com API Gateway",
      "risks"           => [ "vendor lock-in", "latência de rede", "ponto único de falha no gateway" ],
      "recommendations" => [ "implementar circuit breaker", "adicionar retry com backoff exponencial" ],
      "confidence"      => "alta",
      "components"      => [ "API Gateway", "Auth Service", "Report Service", "RabbitMQ" ],
      "best_practices"  => [ "usar health checks", "centralizar logs", "padronizar contratos via OpenAPI" ],
      "generated_at"    => "2026-05-21T10:00:00Z"
    }
  end

  let(:report) do
    build_stubbed(:report,
      document_name: "arquitetura_v2.pdf",
      result: result
    )
  end

  subject(:pdf_content) { described_class.call(report) }

  it "returns a binary string" do
    expect(pdf_content).to be_a(String)
  end

  it "starts with the PDF magic bytes (%PDF)" do
    expect(pdf_content).to start_with("%PDF")
  end

  it "produces a non-empty PDF" do
    expect(pdf_content.bytesize).to be > 1_000
  end

  context "when result has symbol keys" do
    let(:result) do
      {
        summary:         "Arquitetura monolítica",
        risks:           [ "acoplamento alto" ],
        recommendations: [ "extrair serviços" ],
        best_practices:  [ "separar camadas" ],
        confidence:      "média",
        components:      [ "Monolith" ],
        generated_at:    Time.current
      }
    end

    it "does not raise" do
      expect { pdf_content }.not_to raise_error
    end
  end

  context "when optional fields are absent" do
    let(:result) do
      {
        "summary"         => "Arquitetura simples",
        "risks"           => [],
        "recommendations" => [],
        "best_practices"  => [],
        "confidence"      => nil,
        "components"      => [],
        "generated_at"    => nil
      }
    end

    it "does not raise" do
      expect { pdf_content }.not_to raise_error
    end

    it "still returns a valid PDF" do
      expect(pdf_content).to start_with("%PDF")
    end
  end

  context "when result is nil" do
    let(:report) { build_stubbed(:report, document_name: "doc.pdf", result: nil) }

    it "returns nil" do
      expect(pdf_content).to be_nil
    end
  end
end
