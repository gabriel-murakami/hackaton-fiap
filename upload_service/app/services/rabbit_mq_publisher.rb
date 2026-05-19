require "bunny"
require "json"

class RabbitMqPublisher
  def self.publish(queue_name, payload)
    connection = Bunny.new(ENV.fetch("RABBITMQ_URL"))
    connection.start

    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)

    queue.publish(payload.to_json, persistent: true)

    connection.close
  rescue StandardError => e
    Rails.logger.error("Erro ao publicar no RabbitMQ: #{e.message}")
  end
end
