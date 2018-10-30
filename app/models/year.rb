# frozen_string_literal: true

class Year < ApplicationRecord
  before_validation :generate_slug

  validates :value, presence: true, uniqueness: true, length: { is: 4 }
  validates :slug, presence: true

  validate :value_not_in_the_past

  private

  def value_not_in_the_past
    return unless value
    return if value >= Date.today.year

    errors.add(:value, :past)
  end

  def generate_slug
    self.slug = SlugGenerator.new(value.to_s).slug
  end
end
