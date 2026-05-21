require "rails_helper"

RSpec.describe ReportsController, type: :controller do
  before { Report.delete_all }

  describe "GET #index" do
    context "when there are reports" do
      let!(:report_one) { create(:report, document_name: "arch.pdf", created_at: 1.hour.ago) }
      let!(:report_two) { create(:report, document_name: "infra.pdf", created_at: 2.hours.ago) }

      it "returns status 200" do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "returns all reports ordered by created_at desc" do
        get :index
        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to eq([ report_one.id, report_two.id ])
      end
    end

    context "when there are no reports" do
      it "returns status 200 with an empty array" do
        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe "GET #show" do
    context "when the report exists" do
      let!(:report) { create(:report, status: :completed) }

      it "returns status 200" do
        get :show, params: { document_id: report.document_id }
        expect(response).to have_http_status(:ok)
      end

      it "returns a PDF content type" do
        get :show, params: { document_id: report.document_id }
        expect(response.content_type).to eq("application/pdf")
      end

      it "returns binary data starting with the PDF magic bytes" do
        get :show, params: { document_id: report.document_id }
        expect(response.body).to start_with("%PDF")
      end
    end

    context "when the report does not exist" do
      it "returns status 404" do
        get :show, params: { document_id: SecureRandom.uuid }
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message" do
        get :show, params: { document_id: SecureRandom.uuid }
        body = JSON.parse(response.body)
        expect(body["error"]).to eq("Relatório não encontrado para o document_id informado")
      end
    end
  end
end
