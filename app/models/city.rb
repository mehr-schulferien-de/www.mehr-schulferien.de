class City < ApplicationRecord
  before_validation :generate_slug

  validates :name, presence: true, uniqueness: :federal_state
  validates :slug, presence: true, uniqueness: true
  validates :zip_code, presence: true, uniqueness: :country
  validates :country, presence: true, uniqueness: :zip_code
  validates :federal_state, presence: true, uniqueness: :name

  belongs_to :country, primary_key: :code, foreign_key: :country_code, touch: true
  belongs_to :federal_state, primary_key: :code, foreign_key: :federal_state_code, touch: true

  private

  def generate_slug
    slugged_name = SlugGenerator.new(name).slug
    slugged_name_zip_code = SlugGenerator.new(name, zip_code).slug

    self.slug = nil
    self.slug = if City.where(slug: slugged_name).none?
                  slugged_name
                elsif City.where(slug: slugged_name_zip_code).none?
                  slugged_name_zip_code
                end
  end
end
