# frozen_string_literal: true

# TODO: Write tests
class SlugGenerator
  attr_reader :slug

  def initialize(param)
    @param = param
    return if param.blank? || !param.is_a?(String)

    @slug = build
  end

  private

  def build
    convert_german_umlauts(@param.squish).parameterize
  end

  def convert_german_umlauts(value)
    value
      .gsub('Ä', 'ae').gsub('ä', 'ae')
      .gsub('Ö', 'oe').gsub('ö', 'oe')
      .gsub('Ü', 'ue').gsub('ü', 'ue')
      .gsub('ß', 'ss')
  end
end
