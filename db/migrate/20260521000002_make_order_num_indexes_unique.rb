class MakeOrderNumIndexesUnique < ActiveRecord::Migration[8.1]
  def change
    [
      [ :modules,   :course_id ],
      [ :lessons,   :module_id ],
      [ :questions, :quiz_id ]
    ].each do |table, parent|
      remove_index table, [ parent, :order_num ]
      add_index    table, [ parent, :order_num ], unique: true
    end
  end
end
