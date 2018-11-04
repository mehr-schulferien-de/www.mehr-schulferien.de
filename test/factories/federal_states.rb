# frozen_string_literal: true

FactoryBot.define do
  factory :federal_state do
    name { 'Bayern' }
    code { 'BY' }
    country { (Country.find_by(code: 'DE') || create(:country, :deutschland)) }

    trait :rp do
      name { 'Rheinland-Pfalz' }
      code { 'RP' }
      country { (Country.find_by(code: 'DE') || create(:country, :deutschland)) }
    end
  end
end
