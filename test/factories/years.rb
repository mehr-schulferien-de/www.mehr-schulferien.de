# frozen_string_literal: true

FactoryBot.define do
  factory :year do
    value { Date.today.year }
  end
end
