require "rails_helper"

RSpec.describe ReportAnalyzer::FileProcessor do
  describe ".validate!" do
    context "with a valid PDF file" do
      it "does not raise an error" do
        expect { described_class.validate!("pdf content", "diagram.pdf") }.not_to raise_error
      end
    end

    context "with a valid PNG file" do
      it "does not raise an error" do
        expect { described_class.validate!("image data", "diagram.png") }.not_to raise_error
      end
    end

    context "with a valid JPG file" do
      it "does not raise an error" do
        expect { described_class.validate!("image data", "diagram.jpg") }.not_to raise_error
      end
    end

    context "with a valid JPEG file" do
      it "does not raise an error" do
        expect { described_class.validate!("image data", "diagram.jpeg") }.not_to raise_error
      end
    end

    context "with blank file content" do
      it "raises Arquivo vazio for nil" do
        expect { described_class.validate!(nil, "diagram.pdf") }.to raise_error("Arquivo vazio")
      end

      it "raises Arquivo vazio for empty string" do
        expect { described_class.validate!("", "diagram.pdf") }.to raise_error("Arquivo vazio")
      end
    end

    context "with an unsupported file extension" do
      it "raises Formato não suportado for .doc" do
        expect { described_class.validate!("content", "diagram.doc") }.to raise_error("Formato não suportado")
      end

      it "raises Formato não suportado for .txt" do
        expect { described_class.validate!("content", "notes.txt") }.to raise_error("Formato não suportado")
      end
    end
  end

  describe ".process" do
    context "with a PDF file" do
      let(:pdf_content) { "binary pdf content" }
      let(:page1) { double("page", text: "page one text") }
      let(:page2) { double("page", text: "page two text") }
      let(:reader) { instance_double(PDF::Reader, pages: [ page1, page2 ]) }

      before do
        allow(PDF::Reader).to receive(:new).and_return(reader)
      end

      it "returns type :text" do
        result = described_class.process(pdf_content, "document.pdf")
        expect(result[:type]).to eq(:text)
      end

      it "extracts and joins text from all pages" do
        result = described_class.process(pdf_content, "document.pdf")
        expect(result[:content]).to eq("page one text\npage two text")
      end

      it "wraps the content in a StringIO for the PDF reader" do
        expect(PDF::Reader).to receive(:new) do |io|
          expect(io).to be_a(StringIO)
          reader
        end
        described_class.process(pdf_content, "document.pdf")
      end
    end

    context "with a PNG file" do
      let(:image_content) { "binary png data" }

      it "returns type :image" do
        result = described_class.process(image_content, "diagram.png")
        expect(result[:type]).to eq(:image)
      end

      it "returns the raw image binary as content" do
        result = described_class.process(image_content, "diagram.png")
        expect(result[:content]).to eq(image_content)
      end
    end

    context "with a JPG file" do
      let(:image_content) { "binary jpg data" }

      it "returns type :image" do
        result = described_class.process(image_content, "photo.jpg")
        expect(result[:type]).to eq(:image)
      end
    end

    context "with a JPEG file" do
      let(:image_content) { "binary jpeg data" }

      it "returns type :image" do
        result = described_class.process(image_content, "photo.jpeg")
        expect(result[:type]).to eq(:image)
      end
    end

    context "with an unsupported file extension" do
      it "raises Formato inválido" do
        expect { described_class.process("content", "file.bmp") }.to raise_error("Formato inválido")
      end
    end
  end
end
