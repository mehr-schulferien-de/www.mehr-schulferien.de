FactoryBot.define do
  factory :country do
    sequence :name do |n|
      "Deutschland-#{n}"
    end
    code { 'DE' }
  end
end
