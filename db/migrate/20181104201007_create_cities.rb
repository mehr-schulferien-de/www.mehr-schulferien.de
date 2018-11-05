# frozen_string_literal: true

class CreateCities < ActiveRecord::Migration[5.2]
  def change
    create_table :cities do |t|
      t.string :name
      t.string :slug
      t.string :zip_code
      t.string :country_code
      t.string :federal_state_code

      t.timestamps
    end

    add_index :cities, :slug, unique: true
  end
end
