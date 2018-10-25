# frozen_string_literal: true

class Country < ApplicationRecord
  before_validation :generate_slug
  before_validation :upcase_code

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z]+\z/ }, length: { is: 2 }

  private

  def generate_slug
    self.slug = SlugGenerator.new(name).slug
  end

  def upcase_code
    self.code = code.upcase if code
  end
end
