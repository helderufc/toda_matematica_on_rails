class Modulo < ApplicationRecord
  self.table_name = "modules"

  belongs_to :course
  has_many :lessons, foreign_key: "module_id", dependent: :destroy, inverse_of: :modulo
  has_one :quiz, foreign_key: "module_id", dependent: :destroy, inverse_of: :modulo

  validates :name, presence: true, length: { maximum: 50 }
  validates :order_num, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
