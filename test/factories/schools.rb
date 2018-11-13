FactoryBot.define do
  factory :school do
    name { 'Annaschule' }
    phone_number { '0123456789' }
    homepage_url { 'https://google.de' }
    federal_state { (FederalState.find_by(code: 'RP') || create(:federal_state, :rp)) }
    fax_number { '0123456789' }
    sequence(:email_address) { |n| "test@test#{n}.de" }
    country { (Country.find_by(code: 'DE') || create(:country, :deutschland)) }
    city { (City.find_by(name: 'Neuwied') || create(:city)) }
  end
end
