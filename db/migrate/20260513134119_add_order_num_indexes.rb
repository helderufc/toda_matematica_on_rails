class AddOrderNumIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :modules,   [:course_id, :order_num]
    add_index :lessons,   [:module_id, :order_num]
    add_index :questions, [:quiz_id, :order_num]
  end
end
