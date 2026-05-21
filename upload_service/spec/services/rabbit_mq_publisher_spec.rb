require 'rails_helper'

RSpec.describe RabbitMqPublisher do
  describe ".publish" do
    let(:queue_name) { "test_queue" }
    let(:payload) { { document_id: "123", file_url: "https://example.com/test.pdf", filename: "test.pdf" } }

    let(:mock_connection) { double("Bunny::Session") }
    let(:mock_channel) { double("Bunny::Channel") }
    let(:mock_queue) { double("Bunny::Queue") }

    before do
      allow(Bunny).to receive(:new).and_return(mock_connection)
      allow(mock_connection).to receive(:start)
      allow(mock_connection).to receive(:create_channel).and_return(mock_channel)
      allow(mock_channel).to receive(:queue).with(queue_name, durable: true).and_return(mock_queue)
      allow(mock_queue).to receive(:publish)
      allow(mock_connection).to receive(:close)
    end

    it "creates a Bunny connection using RABBITMQ_URL" do
      described_class.publish(queue_name, payload)
      expect(Bunny).to have_received(:new).with(ENV["RABBITMQ_URL"])
    end

    it "starts the connection" do
      described_class.publish(queue_name, payload)
      expect(mock_connection).to have_received(:start)
    end

    it "declares a durable queue with the given name" do
      described_class.publish(queue_name, payload)
      expect(mock_channel).to have_received(:queue).with(queue_name, durable: true)
    end

    it "publishes the payload as persistent JSON" do
      described_class.publish(queue_name, payload)
      expect(mock_queue).to have_received(:publish).with(payload.to_json, persistent: true)
    end

    it "closes the connection after publishing" do
      described_class.publish(queue_name, payload)
      expect(mock_connection).to have_received(:close)
    end

    context "when a StandardError is raised" do
      before do
        allow(mock_connection).to receive(:start).and_raise(StandardError, "Connection failed")
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error message" do
        described_class.publish(queue_name, payload)
        expect(Rails.logger).to have_received(:error)
          .with("Erro ao publicar no RabbitMQ: Connection failed")
      end

      it "does not propagate the error" do
        expect { described_class.publish(queue_name, payload) }.not_to raise_error
      end
    end
  end
end
