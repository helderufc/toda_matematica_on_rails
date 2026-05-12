require "test_helper"

class AiServiceTest < ActiveSupport::TestCase
  # ---------- generate_lesson_content ----------

  test "gera conteúdo a partir de text" do
    result = AiService.generate_lesson_content(text: "Conteúdo da aula de álgebra")
    assert_includes result, "Conteúdo da aula de álgebra"
  end

  test "gera conteúdo a partir de pdf_path quando text está ausente" do
    result = AiService.generate_lesson_content(pdf_path: "/tmp/material.pdf")
    assert_includes result, "material.pdf"
  end

  test "levanta ArgumentError quando não há fonte disponível" do
    assert_raises(ArgumentError) { AiService.generate_lesson_content }
    assert_raises(ArgumentError) { AiService.generate_lesson_content(text: nil, pdf_path: nil) }
    assert_raises(ArgumentError) { AiService.generate_lesson_content(text: "  ", pdf_path: nil) }
  end

  # ---------- generate_quiz ----------

  test "gera a quantidade solicitada de questões" do
    result = AiService.generate_quiz(lessons: [ lessons(:lesson_one) ], quantidade: 4)
    assert_equal 4, result.size
  end

  test "usa quantidade padrão de 5 quando não informada" do
    result = AiService.generate_quiz(lessons: [ lessons(:lesson_one) ])
    assert_equal 5, result.size
  end

  test "cada questão tem exatamente 1 alternativa correta" do
    result = AiService.generate_quiz(lessons: [ lessons(:lesson_one) ])
    result.each do |q|
      corretas = q[:alternatives].count { |a| a[:correct] }
      assert_equal 1, corretas, "Questão '#{q[:statement]}' tem #{corretas} corretas"
    end
  end

  test "cada questão tem order_num sequencial" do
    result = AiService.generate_quiz(lessons: [ lessons(:lesson_one) ], quantidade: 3)
    assert_equal [ 1, 2, 3 ], result.map { |q| q[:order_num] }
  end

  test "levanta ArgumentError quando módulo não tem conteúdo legível" do
    # lesson_two não tem content_editor nem file_path
    assert_raises(ArgumentError) do
      AiService.generate_quiz(lessons: [ lessons(:lesson_two) ])
    end
  end

  test "ignora aulas sem conteúdo mas gera se ao menos uma tiver" do
    # lesson_one tem content, lesson_two não — deve funcionar
    result = AiService.generate_quiz(lessons: [ lessons(:lesson_two), lessons(:lesson_one) ])
    assert result.any?
  end
end
