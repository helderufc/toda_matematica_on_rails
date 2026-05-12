class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string :title, null: false
      t.string :category, null: false, limit: 100
      t.text :description, null: false
      t.string :image_path, limit: 500
      t.timestamps
    end
  end
end
