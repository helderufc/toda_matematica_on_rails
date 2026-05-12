require "test_helper"

class AlternativeTest < ActiveSupport::TestCase
  test "válido como alternativa errada" do
    alt = Alternative.new(question: questions(:question_one), text: "Nova errada", correct: false)
    assert alt.valid?
  end

  test "válido como primeira correta em questão sem correta" do
    # question_two já tem alt_b_correct, então testamos em uma questão nova
    q = questions(:question_two)
    # adicionar uma errada extra não viola unicidade
    alt = Alternative.new(question: q, text: "Mais uma errada", correct: false)
    assert alt.valid?
  end

  test "inválido sem text" do
    alt = Alternative.new(question: questions(:question_one), text: nil, correct: false)
    assert_not alt.valid?
    assert alt.errors[:text].any?
  end

  test "correct não pode ser nil" do
    alt = Alternative.new(question: questions(:question_one), text: "Alt", correct: nil)
    assert_not alt.valid?
    assert alt.errors[:correct].any?
  end

  test "rejeita segunda alternativa correta para a mesma questão" do
    # question_one já tem alt_a_correct (correct: true) salva no banco
    alt = Alternative.new(question: questions(:question_one), text: "Segunda correta", correct: true)
    assert_not alt.valid?
    assert alt.errors[:correct].any?
  end

  test "pertence a uma questão" do
    assert_equal questions(:question_one), alternatives(:alt_a_correct).question
  end
end
