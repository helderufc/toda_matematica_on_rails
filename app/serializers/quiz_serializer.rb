class QuizSerializer
  include Alba::Resource

  attributes :id, :show_wrong_answers, :show_correct_answers, :show_points

  many :questions, resource: QuestionSerializer
end
