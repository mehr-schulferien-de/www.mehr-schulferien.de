class CreateCountries < ActiveRecord::Migration[5.2]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :slug
      t.string :code

      t.timestamps
    end

    add_index :countries, :name, unique: true
    add_index :countries, :slug, unique: true
    add_index :countries, :code, unique: true
  end
end
