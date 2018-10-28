# frozen_string_literal: true

class FederalState < ApplicationRecord
  before_validation :generate_slug

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z]+\z/ }, length: { is: 2 }

  belongs_to :country, primary_key: :code, foreign_key: :country_code, touch: true

  private

  def generate_slug
    self.slug = SlugGenerator.new(name).slug
  end
end
