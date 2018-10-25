# frozen_string_literal: true

require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  def setup
    @empty_country = build(:country, name: nil)
  end

  test 'validate presence of name' do
    assert_not @empty_country.valid?
    assert @empty_country.errors.key?(:name)
  end

  test 'validate uniqueness of name' do
    country = create(:country)
    new_country = build(:country, name: country.name)

    assert_not new_country.save
    assert new_country.errors.key?(:name)
  end

  test 'validates presence of slug' do
    country = create(:country, name: 'Österreich')

    assert_equal 'oesterreich', country.slug
  end

  test 'validate uniqueness of slug' do
    country = create(:country, name: 'Österreich', slug: 'oesterreich')
    new_country = build(:country, name: country.name, slug: country.slug)

    assert_not new_country.save
    assert new_country.errors.key?(:slug)
  end

  test 'validates presence of code' do
    country = build(:country, code: nil)

    assert_not country.valid?
    assert country.errors.key?(:code)
  end

  test 'validates uniqueness of code' do
    country = create(:country)
    new_country = build(:country, code: country.code)

    assert_not new_country.valid?
    assert new_country.errors.key?(:code)
  end

  test 'code should only include characters' do
    country = build(:country, code: 123)

    assert_not country.valid?
    assert country.errors.key?(:code)
  end

  test 'code length should be 2' do
    country = build(:country, code: 'DEE')

    assert_not country.valid?
    assert country.errors.key?(:code)

    country.code = 'D'

    assert_not country.valid?
    assert country.errors.key?(:code)
  end

  test 'code should be saved upcased' do
    country = create(:country, name: 'Österreich', code: 'au')

    assert_equal 'AU', country.code
  end

  test 'should has_many federal_states' do
    country = create(:country, federal_states: [create(:federal_state)])

    assert_equal 1, country.federal_states.count
    assert_equal FederalState, country.federal_states.first.class
  end
end
