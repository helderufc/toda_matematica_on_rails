class Quiz < ApplicationRecord
  belongs_to :modulo, class_name: "Modulo", foreign_key: "module_id", inverse_of: :quiz
  has_many :questions, dependent: :destroy, inverse_of: :quiz

  accepts_nested_attributes_for :questions

  validates :module_id, uniqueness: { message: "Este módulo já possui um quiz" }
end
