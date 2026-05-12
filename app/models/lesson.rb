class Lesson < ApplicationRecord
  belongs_to :modulo, class_name: "Modulo", foreign_key: "module_id", inverse_of: :lessons

  validates :name, presence: true
  validates :order_num, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :file_type, inclusion: { in: %w[pdf], message: "deve ser pdf" }, allow_nil: true
end
