class CreateModules < ActiveRecord::Migration[8.1]
  def change
    create_table :modules do |t|
      t.string :name, null: false, limit: 50
      t.integer :order_num, null: false
      t.string :image_path, limit: 500
      t.bigint :course_id, null: false
      t.timestamps
    end

    add_index :modules, :course_id
    add_foreign_key :modules, :courses, on_delete: :cascade
  end
end
