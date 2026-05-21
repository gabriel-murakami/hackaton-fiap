require "rails_helper"

RSpec.describe ReportWorker do
  subject(:worker) { described_class.new }

  let(:document_id) { SecureRandom.uuid }
  let(:filename) { "architecture.pdf" }
  let(:file_url) { "http://minio:9000/files/architecture.pdf" }
  let(:file_content) { "binary pdf content" }
  let(:ai_result) do
    {
      "summary" => "Serverless architecture",
      "risks" => [ "cold start latency" ],
      "recommendations" => [ "add monitoring" ],
      "confidence" => "alta"
    }
  end

  let(:raw_post) do
    {
      document_id: document_id,
      filename: filename,
      file_url: file_url
    }.to_json
  end

  before do
    allow(Rails.logger).to receive(:tagged).and_yield
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:fatal)
    allow(worker).to receive(:ack!)
    allow(worker).to receive(:reject!)
    allow(ReportAnalyzer::Orchestrator).to receive(:call).and_return(ai_result)
  end

  describe "#work" do
    context "when file download and analysis succeed" do
      before do
        fake_file = instance_double(StringIO, read: file_content)
        allow(URI).to receive(:open).with(file_url).and_return(fake_file)
      end

      it "calls ack!" do
        expect(worker).to receive(:ack!)
        worker.work(raw_post)
      end

      it "does not call reject!" do
        expect(worker).not_to receive(:reject!)
        worker.work(raw_post)
      end

      it "calls Orchestrator with the downloaded file content and filename" do
        expect(ReportAnalyzer::Orchestrator).to receive(:call).with(
          file: file_content,
          filename: filename,
          report: instance_of(Report)
        )
        worker.work(raw_post)
      end

      it "persists the report as completed with the AI result" do
        worker.work(raw_post)

        report = Report.find_by(document_id: document_id)
        expect(report.status).to eq("completed")
        expect(report.result).to eq(ai_result)
      end
    end

    context "when Orchestrator returns nil" do
      before do
        fake_file = instance_double(StringIO, read: file_content)
        allow(URI).to receive(:open).with(file_url).and_return(fake_file)
        allow(ReportAnalyzer::Orchestrator).to receive(:call).and_return(nil)
      end

      it "still calls ack!" do
        expect(worker).to receive(:ack!)
        worker.work(raw_post)
      end

      it "does not persist the report" do
        worker.work(raw_post)
        expect(Report.find_by(document_id: document_id)).to be_nil
      end
    end

    context "when file download raises OpenURI::HTTPError" do
      before do
        allow(URI).to receive(:open).with(file_url)
          .and_raise(OpenURI::HTTPError.new("403 Forbidden", StringIO.new))
      end

      it "calls reject!" do
        expect(worker).to receive(:reject!)
        worker.work(raw_post)
      end

      it "does not call ack!" do
        expect(worker).not_to receive(:ack!)
        worker.work(raw_post)
      end

      it "marks the report as failed" do
        worker.work(raw_post)

        report = Report.find_by(document_id: document_id)
        expect(report.status).to eq("failed")
      end
    end

    context "when an unexpected StandardError is raised" do
      before do
        allow(URI).to receive(:open).with(file_url)
          .and_raise(StandardError.new("unexpected error"))
      end

      it "calls reject!" do
        expect(worker).to receive(:reject!)
        worker.work(raw_post)
      end

      it "does not call ack!" do
        expect(worker).not_to receive(:ack!)
        worker.work(raw_post)
      end

      it "marks the report as failed" do
        worker.work(raw_post)

        report = Report.find_by(document_id: document_id)
        expect(report.status).to eq("failed")
      end
    end
  end
end
