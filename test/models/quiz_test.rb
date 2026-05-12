require "test_helper"

class QuizTest < ActiveSupport::TestCase
  test "válido para módulo sem quiz" do
    quiz = Quiz.new(modulo: modules(:module_empty))
    assert quiz.valid?
  end

  test "inválido quando módulo já tem quiz" do
    quiz = Quiz.new(modulo: modules(:module_one))
    assert_not quiz.valid?
    assert quiz.errors[:module_id].any?
  end

  test "pertence a um módulo" do
    assert_equal modules(:module_one), quizzes(:quiz_one).modulo
  end

  test "tem muitas questões" do
    assert_equal 2, quizzes(:quiz_one).questions.count
  end

  test "cascade: destruir quiz destrói questões" do
    quiz = quizzes(:quiz_one)
    question_ids = quiz.questions.pluck(:id)
    assert question_ids.any?
    quiz.destroy
    assert_equal 0, Question.where(id: question_ids).count
  end
end
