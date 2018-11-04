# frozen_string_literal: true

FactoryBot.define do
  factory :city do
    name { 'Neuwied' }
    zip_code { '56564' }
    country { (Country.find_by(code: 'DE') || create(:country, :deutschland)) }
    federal_state { (FederalState.find_by(code: 'RP') || create(:federal_state, :rp)) }
  end
end
