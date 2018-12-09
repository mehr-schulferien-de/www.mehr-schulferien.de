class CreatePeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :periods do |t|
      t.date :starts_on
      t.date :ends_on
      t.string :name
      t.string :slug
      t.integer :length
      t.string :category_slug
      t.string :school_slug
      t.string :city_slug
      t.string :federal_state_slug
      t.string :country_slug

      t.timestamps
    end

    add_index :periods, :slug, unique: true
  end
end
