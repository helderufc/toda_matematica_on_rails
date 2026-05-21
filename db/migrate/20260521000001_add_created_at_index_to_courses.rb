class AddCreatedAtIndexToCourses < ActiveRecord::Migration[8.1]
  def change
    add_index :courses, :created_at
  end
end
