class CreateFederalStates < ActiveRecord::Migration[5.2]
  def change
    create_table :federal_states do |t|
      t.string :name
      t.string :slug
      t.string :code
      t.string :country_code

      t.timestamps
    end

    add_index :federal_states, :name, unique: true
    add_index :federal_states, :slug, unique: true
    add_index :federal_states, :code, unique: true
    add_index :federal_states, :country_code
  end
end
