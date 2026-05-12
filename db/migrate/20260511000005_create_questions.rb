class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.text :statement, null: false
      t.integer :points, null: false, default: 1
      t.integer :order_num, null: false
      t.bigint :quiz_id, null: false
      t.timestamps
    end

    add_index :questions, :quiz_id
    add_foreign_key :questions, :quizzes, on_delete: :cascade
  end
end
