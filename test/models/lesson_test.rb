require "test_helper"

class LessonTest < ActiveSupport::TestCase
  def build_lesson(overrides = {})
    Lesson.new({ modulo: modules(:module_one), name: "Nova Aula", order_num: 99 }.merge(overrides))
  end

  test "válido com atributos obrigatórios" do
    assert build_lesson.valid?
  end

  test "inválido sem name" do
    assert_not build_lesson(name: nil).valid?
  end

  test "inválido sem order_num" do
    assert_not build_lesson(order_num: nil).valid?
  end

  test "order_num deve ser positivo" do
    assert_not build_lesson(order_num: 0).valid?
    assert_not build_lesson(order_num: -5).valid?
  end

  test "file_type aceita apenas pdf" do
    assert_not build_lesson(file_type: "doc").valid?
    assert_not build_lesson(file_type: "mp4").valid?
    assert build_lesson(file_type: "pdf").valid?
  end

  test "file_type pode ser nil" do
    assert build_lesson(file_type: nil).valid?
  end

  test "pertence a um módulo" do
    assert_equal modules(:module_one), lessons(:lesson_one).modulo
  end
end
