require 'test_helper'

class CityTest < ActiveSupport::TestCase
  test 'validate presence of name' do
    city = build(:city, name: nil)

    assert_not city.valid?
    assert city.errors.key?(:name)
  end

  test 'validates presence of slug' do
    city = create(:city, name: 'Rothenburg ob der Tauber')

    assert_equal 'rothenburg-ob-der-tauber', city.slug
  end

  test 'validate presence of zip_code' do
    city = build(:city, zip_code: nil)

    assert_not city.valid?
    assert city.errors.key?(:zip_code)
  end

  test 'validate uniqueness of zip_code -> in scope of slug and name' do
    create(:city, name: 'Rothenburg ob der Tauber', zip_code: '12345')
    city = build(:city, name: 'Rothenburg ob der Tauber', zip_code: '12345')

    assert_not city.valid?
    assert city.errors.key?(:zip_code)
  end

  test 'validate presence of country' do
    city = build(:city, country: nil)

    assert_not city.valid?
    assert city.errors.key?(:country)
  end

  test 'validate presence of federal_state' do
    city = build(:city, federal_state: nil)

    assert_not city.valid?
    assert city.errors.key?(:federal_state)
  end
end
