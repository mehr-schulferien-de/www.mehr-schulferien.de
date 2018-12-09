FactoryBot.define do
  factory :period do
    starts_on { "2018-12-09" }
    ends_on { "2018-12-09" }
    name { "MyString" }
    slug { "MyString" }
    length { 1 }
    category_slug { "MyString" }
    school_slug { "MyString" }
    city_slug { "MyString" }
    federal_state_slug { "MyString" }
    country_slug { "MyString" }
  end
end
