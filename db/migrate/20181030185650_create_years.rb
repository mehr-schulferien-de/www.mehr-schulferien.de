# frozen_string_literal: true

class CreateYears < ActiveRecord::Migration[5.2]
  def change
    create_table :years do |t|
      t.integer :value
      t.string :slug

      t.timestamps
    end

    add_index :years, :value, unique: true
    add_index :years, :slug, unique: true
  end
end
