class CreateAlternatives < ActiveRecord::Migration[8.1]
  def change
    create_table :alternatives do |t|
      t.text :text, null: false
      t.boolean :correct, null: false, default: false
      t.bigint :question_id, null: false
      t.timestamps
    end

    add_index :alternatives, :question_id
    add_foreign_key :alternatives, :questions, on_delete: :cascade
  end
end
