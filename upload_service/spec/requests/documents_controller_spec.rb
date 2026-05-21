require 'rails_helper'

RSpec.describe DocumentsController, type: :request do
  let(:test_file_url) { "https://example.com/test.pdf" }

  let(:temp_file) do
    Tempfile.new([ "test", ".pdf" ]).tap do |f|
      f.write("PDF content")
      f.rewind
    end
  end

  let(:uploaded_file) { Rack::Test::UploadedFile.new(temp_file.path, "application/pdf") }

  before do
    allow_any_instance_of(ActiveStorage::Blob).to receive(:url).and_return(test_file_url)
  end

  describe "POST /documents" do
    context "when the document is saved successfully" do
      before do
        allow(RabbitMqPublisher).to receive(:publish)
      end

      it "returns HTTP 201" do
        post "/documents", params: { title: "Test Doc", file: uploaded_file }
        expect(response).to have_http_status(:created)
      end

      it "returns the document_id and success message" do
        post "/documents", params: { title: "Test Doc", file: uploaded_file }
        body = JSON.parse(response.body)
        expect(body["message"]).to eq("Upload realizado e enviado para processamento.")
        expect(body["document_id"]).to be_present
      end

      it "publishes the payload to RabbitMQ" do
        post "/documents", params: { title: "Test Doc", file: uploaded_file }
        expect(RabbitMqPublisher).to have_received(:publish).with(
          "reports_queue",
          hash_including(:document_id, :file_url, :filename)
        )
      end
    end

    context "when the document fails to save" do
      before do
        allow_any_instance_of(Document).to receive(:save).and_return(false)
      end

      it "returns HTTP 422" do
        post "/documents", params: { title: "Test Doc", file: uploaded_file }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an errors array" do
        post "/documents", params: { title: "Test Doc", file: uploaded_file }
        body = JSON.parse(response.body)
        expect(body["errors"]).to be_an(Array)
      end
    end
  end

  describe "GET /documents/:document_id" do
    let(:document) { create(:document) }

    before do
      document.file.attach(
        io: StringIO.new("PDF content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
    end

    it "returns HTTP 200" do
      get "/documents/#{document.id}"
      expect(response).to have_http_status(:ok)
    end

    it "returns the document data" do
      get "/documents/#{document.id}"
      body = JSON.parse(response.body)
      expect(body["document_id"]).to eq(document.id)
      expect(body["file_url"]).to eq(test_file_url)
      expect(body["filename"]).to eq("test.pdf")
    end
  end
end
