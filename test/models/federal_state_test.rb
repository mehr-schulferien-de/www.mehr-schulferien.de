# frozen_string_literal: true

require 'test_helper'

class FederalStateTest < ActiveSupport::TestCase
  test 'validate presence of name' do
    federal_state = build(:federal_state, name: nil)

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:name)
  end

  test 'validate uniqueness of name' do
    federal_state = create(:federal_state)
    new_federal_state = build(:federal_state, name: federal_state.name)

    assert_not new_federal_state.save
    assert new_federal_state.errors.key?(:name)
  end

  test 'validates presence of slug' do
    federal_state = create(:federal_state, name: 'Baden-Württemberg')

    assert_equal 'baden-wuerttemberg', federal_state.slug
  end

  test 'validate uniqueness of slug' do
    federal_state = create(:federal_state)
    new_federal_state = build(:federal_state, slug: federal_state.slug)

    assert_not new_federal_state.save
    assert new_federal_state.errors.key?(:slug)
  end

  test 'validates presence of code' do
    federal_state = build(:federal_state, code: nil)

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:code)
  end

  test 'validates uniqueness of code' do
    federal_state = create(:federal_state)
    new_federal_state = build(:federal_state, code: federal_state.code)

    assert_not new_federal_state.valid?
    assert new_federal_state.errors.key?(:code)
  end

  test 'code should only include characters' do
    federal_state = build(:federal_state, code: 123)

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:code)
  end

  test 'code length should be 2' do
    federal_state = build(:federal_state, code: 'BYY')

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:code)

    federal_state.code = 'B'

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:code)
  end

  test 'code should be saved upcased' do
    federal_state = create(:federal_state, name: 'Bayern', code: 'by')

    assert_equal 'by', federal_state.code
  end

  test 'validate presence of country code' do
    federal_state = build(:federal_state, name: 'Bayern', code: 'by', country_code: nil)

    assert_not federal_state.valid?
    assert federal_state.errors.key?(:country)
  end
end
