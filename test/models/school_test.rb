# frozen_string_literal: true

require 'test_helper'

class SchoolTest < ActiveSupport::TestCase
  test 'validate presence of name' do
    school = build(:school, name: nil)

    assert_not school.valid?
    assert school.errors.key?(:name)
  end

  test 'validates presence of slug' do
    school = create(:school, name: 'Grundschule Neuwied', city: create(:city, zip_code: '12345'))

    assert_equal '12345-grundschule-neuwied', school.slug
  end

  test 'validate uniqueness of slug' do
    city = create(:city, zip_code: '12345')
    create(:school, name: 'Annaschule', city: city)
    school = build(:school, name: 'Annaschule', city: city)

    assert_not school.valid?
    assert school.errors.key?(:slug)
  end

  test 'validates presence of phone_number' do
    school = build(:school, phone_number: nil)

    assert_not school.valid?
    assert school.errors.key?(:phone_number)
  end

  test 'validates presence of homepage_url' do
    school = build(:school, homepage_url: nil)

    assert_not school.valid?
    assert school.errors.key?(:homepage_url)
  end

  test 'validates presence of federal_state' do
    school = build(:school, federal_state: nil)

    assert_not school.valid?
    assert school.errors.key?(:federal_state)
  end

  test 'validates presence of email_address' do
    school = build(:school, email_address: nil)

    assert_not school.valid?
    assert school.errors.key?(:email_address)
  end

  test 'validates presence of country' do
    school = build(:school, country: nil)

    assert_not school.valid?
    assert school.errors.key?(:country)
  end

  test 'validates presence of city' do
    school = build(:school, city: nil)

    assert_not school.valid?
    assert school.errors.key?(:city)
  end
end
