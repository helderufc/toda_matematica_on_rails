class Course < ApplicationRecord
  has_many :modulos, class_name: "Modulo", foreign_key: "course_id", dependent: :destroy

  validates :title, presence: true
  validates :category, presence: true, length: { maximum: 100 }
  validates :description, presence: true
end
