class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :value
      t.string :slug

      t.timestamps
    end

    add_index :categories, :value, unique: true
    add_index :categories, :slug, unique: true
  end
end
