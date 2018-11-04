# frozen_string_literal: true

# TODO: Write tests
class SlugGenerator
  attr_reader :slug

  def initialize(*params)
    return if params.any?(&:blank?) || !params.all? { |param| param.is_a?(String) }

    @params = params
    @slug = build
  end

  private

  def build
    [].tap do |tmp_slug|
      @params.each do |param|
        tmp_slug << convert_german_umlauts(param.squish).parameterize
      end
    end.join('-')
  end

  def convert_german_umlauts(value)
    value
      .gsub('Ä', 'ae').gsub('ä', 'ae')
      .gsub('Ö', 'oe').gsub('ö', 'oe')
      .gsub('Ü', 'ue').gsub('ü', 'ue')
      .gsub('ß', 'ss')
  end
end
