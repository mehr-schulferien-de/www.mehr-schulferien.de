# frozen_string_literal: true

class School < ApplicationRecord
  before_validation :generate_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :homepage_url, presence: true # TODO: format validation
  validates :federal_state, presence: true
  validates :fax_number, presence: true
  validates :email_address, presence: true # TODO: format validation
  validates :country, presence: true
  validates :city, presence: true

  validate :validate_phone_number

  belongs_to :city, primary_key: :slug, foreign_key: :city_slug, touch: true
  belongs_to :country, primary_key: :code, foreign_key: :country_code
  belongs_to :federal_state, primary_key: :code, foreign_key: :federal_state_code

  private

  def generate_slug
    return if city.nil?

    self.slug = SlugGenerator.new(city.zip_code, name).slug
  end

  # TODO: Validate the format etc.
  def validate_phone_number
    return if phone_number.nil? || phone_number.present?

    errors.add(:phone_number, 'Please add a valid phone number')
  end
end
