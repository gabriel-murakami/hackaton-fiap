FactoryBot.define do
  factory :report do
    result { nil }
    document_id { SecureRandom.uuid }
    document_name { "architecture.pdf" }
    status { :pending }
  end
end
