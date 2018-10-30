# frozen_string_literal: true

class Category < ApplicationRecord
  before_validation :generate_slug

  validates :value, presence: true, uniqueness: true

  private

  def generate_slug
    self.slug = SlugGenerator.new(value).slug
  end
end
