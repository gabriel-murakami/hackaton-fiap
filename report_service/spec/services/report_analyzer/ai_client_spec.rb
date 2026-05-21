require "rails_helper"

RSpec.describe ReportAnalyzer::AiClient do
  let(:gemini_response_text) do
    '{"componentes":["API"],"descricao_arquitetura":"desc","riscos":[],"boas_praticas":[],"recomendacoes":[],"confianca":"alta"}'
  end

  let(:gemini_response_body) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => gemini_response_text }
            ]
          }
        }
      ]
    }.to_json
  end

  let(:http_response) { instance_double(Net::HTTPResponse, body: gemini_response_body) }

  before do
    stub_const("ENV", ENV.to_h.merge("GEMINI_API_KEY" => "fake-api-key"))
    allow(Net::HTTP).to receive(:post).and_return(http_response)
    allow(Rails.logger).to receive(:info)
  end

  describe ".analyze" do
    context "with text content" do
      let(:content) { { type: :text, content: "architecture description text" } }
      let(:prompt) { "Analyze the architecture" }

      it "makes a POST request to the Gemini API" do
        expect(Net::HTTP).to receive(:post)
        described_class.analyze(content: content, prompt: prompt)
      end

      it "returns the extracted JSON text from the response" do
        result = described_class.analyze(content: content, prompt: prompt)
        expect(result).to eq(gemini_response_text)
      end
    end

    context "with image content" do
      let(:image_binary) { "fake binary image" }
      let(:content) { { type: :image, content: image_binary } }
      let(:prompt) { "Analyze the diagram" }

      it "makes a POST request to the Gemini API" do
        expect(Net::HTTP).to receive(:post)
        described_class.analyze(content: content, prompt: prompt)
      end

      it "returns the extracted text from the response" do
        result = described_class.analyze(content: content, prompt: prompt)
        expect(result).to eq(gemini_response_text)
      end
    end
  end

  describe ".build_body" do
    context "when content type is :text" do
      let(:content) { { type: :text, content: "some architecture text" } }

      it "builds a request body with a single text part" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        parts = body.dig(:contents, 0, :parts)
        expect(parts.length).to eq(1)
      end

      it "includes the prompt and content in the text part" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        text = body.dig(:contents, 0, :parts, 0, :text)
        expect(text).to include("my prompt")
        expect(text).to include("some architecture text")
      end

      it "includes the system rules in the text part" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        text = body.dig(:contents, 0, :parts, 0, :text)
        expect(text).to include("especialista em arquitetura de software")
      end
    end

    context "when content type is :image" do
      let(:image_data) { "raw image bytes" }
      let(:content) { { type: :image, content: image_data } }

      it "builds a request body with two parts (text + inline_data)" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        parts = body.dig(:contents, 0, :parts)
        expect(parts.length).to eq(2)
      end

      it "sets the mime type to image/png" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        mime = body.dig(:contents, 0, :parts, 1, :inline_data, :mime_type)
        expect(mime).to eq("image/png")
      end

      it "base64-encodes the image data" do
        body = described_class.build_body(content: content, prompt: "my prompt")
        encoded = body.dig(:contents, 0, :parts, 1, :inline_data, :data)
        expect(encoded).to eq(Base64.strict_encode64(image_data))
      end
    end

    context "when content type is unknown" do
      let(:content) { { type: :csv, content: "data" } }

      it "raises Tipo inválido" do
        expect { described_class.build_body(content: content, prompt: "prompt") }.to raise_error("Tipo inválido")
      end
    end
  end

  describe ".extract_text" do
    context "when the response contains a plain JSON text" do
      let(:response) do
        {
          "candidates" => [
            { "content" => { "parts" => [ { "text" => '{"key":"value"}' } ] } }
          ]
        }
      end

      it "returns the text as-is" do
        expect(described_class.extract_text(response)).to eq('{"key":"value"}')
      end
    end

    context "when the response wraps JSON in a markdown code block" do
      let(:response) do
        {
          "candidates" => [
            { "content" => { "parts" => [ { "text" => "```json\n{\"key\":\"value\"}\n```" } ] } }
          ]
        }
      end

      it "strips the markdown formatting and returns clean JSON" do
        expect(described_class.extract_text(response)).to eq('{"key":"value"}')
      end
    end

    context "when the candidates list is empty" do
      let(:response) { { "candidates" => [] } }

      it "returns nil" do
        expect(described_class.extract_text(response)).to be_nil
      end
    end

    context "when the response is missing the candidates key" do
      let(:response) { {} }

      it "returns nil" do
        expect(described_class.extract_text(response)).to be_nil
      end
    end
  end
end
