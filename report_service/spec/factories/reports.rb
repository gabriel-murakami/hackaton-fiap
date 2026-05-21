FactoryBot.define do
  factory :report do
    result do
      {
        "summary"         => "Arquitetura baseada em microsserviços",
        "risks"           => [ "vendor lock-in" ],
        "recommendations" => [ "implementar circuit breaker" ],
        "best_practices"  => [ "usar health checks" ],
        "confidence"      => "alta",
        "components"      => [ "API Gateway", "Auth Service" ],
        "generated_at"    => Time.current.iso8601
      }
    end
    document_id { SecureRandom.uuid }
    document_name { "architecture.pdf" }
    status { :pending }
  end
end
