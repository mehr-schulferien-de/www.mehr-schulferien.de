# frozen_string_literal: true
# TODO: Add unique validation for name, zip_code, country and federal_state (if possible ;-))
class City < ApplicationRecord
  before_validation :generate_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :zip_code, presence: true
  validates :country, presence: true
  validates :federal_state, presence: true

  belongs_to :country, primary_key: :code, foreign_key: :country_code, touch: true
  belongs_to :federal_state, primary_key: :code, foreign_key: :federal_state_code, touch: true

  private

  def generate_slug
    self.slug = SlugGenerator.new(zip_code, name).slug
  end
end
