# frozen_string_literal: true

class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools do |t|
      t.string :name
      t.string :phone_number
      t.string :slug
      t.string :homepage_url
      t.string :federal_state_code
      t.string :fax_number
      t.string :email_address
      t.string :country_code
      t.string :city_slug

      t.timestamps
    end

    add_index :schools, :slug, unique: true
    add_index :schools, :federal_state_code
    add_index :schools, :country_code
    add_index :schools, :city_slug
  end
end
