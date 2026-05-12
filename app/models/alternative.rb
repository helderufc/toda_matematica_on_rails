class Alternative < ApplicationRecord
  belongs_to :question, inverse_of: :alternatives

  validates :text, presence: true
  validates :correct, inclusion: { in: [ true, false ] }

  validate :only_one_correct_per_question, if: :correct?

  private

  def only_one_correct_per_question
    existing = question.alternatives.where(correct: true)
    existing = existing.where.not(id: id) if persisted?
    errors.add(:correct, "já existe uma alternativa correta nesta pergunta") if existing.exists?
  end
end
