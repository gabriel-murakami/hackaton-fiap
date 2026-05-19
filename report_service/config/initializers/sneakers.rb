Sneakers.configure(
  connection: Bunny.new(ENV.fetch("RABBITMQ_URL")),
  workers: 1,
  env: ENV["RAILS_ENV"],
  hooks: {
    before_fork: -> { ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord) },
    after_fork: -> { ActiveRecord::Base.establish_connection if defined?(ActiveRecord) }
  }
)

Sneakers.logger = ActiveSupport::Logger.new(STDOUT)
Sneakers.logger.level = Logger::INFO

Rails.logger = ActiveSupport::TaggedLogging.new(Sneakers.logger)
