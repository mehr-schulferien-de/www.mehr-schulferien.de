# frozen_string_literal: true

FactoryBot.define do
  factory :country do
    name { 'Schweiz' }
    code { 'CH' }

    trait :deutschland do
      name { 'Deutschland' }
      code { 'DE' }
    end
  end
end
