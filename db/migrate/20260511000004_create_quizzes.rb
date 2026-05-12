class CreateQuizzes < ActiveRecord::Migration[8.1]
  def change
    create_table :quizzes do |t|
      t.bigint :module_id, null: false
      t.boolean :show_wrong_answers, null: false, default: false
      t.boolean :show_correct_answers, null: false, default: false
      t.boolean :show_points, null: false, default: false
      t.timestamps
    end

    add_index :quizzes, :module_id, unique: true
    add_foreign_key :quizzes, :modules, on_delete: :cascade
  end
end
