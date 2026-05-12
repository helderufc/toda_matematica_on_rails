class CreateLessons < ActiveRecord::Migration[8.1]
  def change
    create_table :lessons do |t|
      t.string :name, null: false
      t.integer :order_num, null: false
      t.string :file_path, limit: 500
      t.string :file_type, limit: 10
      t.text :content_editor
      t.bigint :module_id, null: false
      t.timestamps
    end

    add_index :lessons, :module_id
    add_foreign_key :lessons, :modules, on_delete: :cascade
  end
end
