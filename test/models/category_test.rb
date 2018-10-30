# frozen_string_literal: true

require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  test 'validate presence of value' do
    category = build(:category, value: nil)

    assert_not category.valid?
    assert category.errors.key?(:value)
  end

  test 'validate uniqueness of name' do
    category = create(:category)
    new_category = build(:category, value: category.value)

    assert_not new_category.save
    assert new_category.errors.key?(:value)
  end

  test 'validate presence of slug' do
    category = create(:category, value: 'Ferien')

    assert_equal 'ferien', category.slug
  end
end
