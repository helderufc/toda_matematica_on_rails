class Question < ApplicationRecord
  belongs_to :quiz, inverse_of: :questions
  has_many :alternatives, dependent: :destroy, inverse_of: :question

  accepts_nested_attributes_for :alternatives

  validates :statement, presence: true
  validates :order_num, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :points, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  validate :alternatives_must_be_valid

  private

  def alternatives_must_be_valid
    pending = alternatives.reject(&:marked_for_destruction?)
    return if pending.empty?

    errors.add(:alternatives, "deve ter no mínimo 2") if pending.size < 2
    errors.add(:alternatives, "deve ter exatamente 1 correta") if pending.count(&:correct) != 1
  end
end
