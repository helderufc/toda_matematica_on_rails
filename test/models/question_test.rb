require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  def build_question(overrides = {})
    q = Question.new({ quiz: quizzes(:quiz_one), statement: "Pergunta?", order_num: 99, points: 1 }.merge(overrides))
    q.alternatives.build(text: "Certa", correct: true)
    q.alternatives.build(text: "Errada", correct: false)
    q
  end

  test "válido com 2 alternativas e exatamente 1 correta" do
    assert build_question.valid?
  end

  test "inválido sem statement" do
    assert_not build_question(statement: nil).valid?
  end

  test "inválido sem order_num" do
    assert_not build_question(order_num: nil).valid?
  end

  test "order_num deve ser inteiro positivo" do
    assert_not build_question(order_num: 0).valid?
    assert_not build_question(order_num: -1).valid?
  end

  test "points deve ser positivo quando informado" do
    assert_not build_question(points: 0).valid?
    assert build_question(points: 5).valid?
  end

  test "inválido com menos de 2 alternativas" do
    q = Question.new(quiz: quizzes(:quiz_one), statement: "Q?", order_num: 99)
    q.alternatives.build(text: "Única", correct: true)
    assert_not q.valid?
    assert q.errors[:alternatives].any?
  end

  test "inválido sem nenhuma alternativa correta" do
    q = Question.new(quiz: quizzes(:quiz_one), statement: "Q?", order_num: 99)
    q.alternatives.build(text: "A", correct: false)
    q.alternatives.build(text: "B", correct: false)
    assert_not q.valid?
    assert_includes q.errors[:alternatives].join, "correta"
  end

  test "inválido com duas alternativas corretas" do
    q = Question.new(quiz: quizzes(:quiz_one), statement: "Q?", order_num: 99)
    q.alternatives.build(text: "A", correct: true)
    q.alternatives.build(text: "B", correct: true)
    assert_not q.valid?
  end

  test "sem alternativas em memória ignora validação de alternativas" do
    q = Question.new(quiz: quizzes(:quiz_one), statement: "Q?", order_num: 99)
    q.valid?
    assert_empty q.errors[:alternatives]
  end

  test "tem muitas alternativas" do
    assert_equal 3, questions(:question_one).alternatives.count
  end
end
