# frozen_string_literal: true

require 'test_helper'

class YearTest < ActiveSupport::TestCase
  test 'validate presence of value' do
    year = build(:year, value: nil)

    assert_not year.valid?
    assert year.errors.key?(:value)
  end

  test 'validate uniqueness of name' do
    year = create(:year)
    new_year = build(:year, value: year.value)

    assert_not new_year.save
    assert new_year.errors.key?(:value)
  end

  test 'validate that value is a year with the length of 4 characters' do
    year = build(:year, value: Date.today.strftime('%y'))

    assert_not year.valid?
    assert year.errors.key?(:value)

    year.value = 12_345

    assert_not year.valid?
    assert year.errors.key?(:value)
  end

  test 'validate that value is not in the past' do
    year = build(:year, value: Date.today.year - 5)

    assert_not year.valid?
    assert year.errors.key?(:value)
  end

  test 'validate presence of slug' do
    year = create(:year, value: Date.today.year + 1)

    assert_equal (Date.today.year + 1).to_s, year.slug
  end
end
