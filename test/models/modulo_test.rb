require "test_helper"

class ModuloTest < ActiveSupport::TestCase
  def build_modulo(overrides = {})
    Modulo.new({ course: courses(:math_101), name: "Novo Módulo", order_num: 99 }.merge(overrides))
  end

  test "válido com atributos obrigatórios" do
    assert build_modulo.valid?
  end

  test "inválido sem name" do
    assert_not build_modulo(name: nil).valid?
  end

  test "name respeita limite de 50 caracteres" do
    assert_not build_modulo(name: "a" * 51).valid?
    assert build_modulo(name: "a" * 50).valid?
  end

  test "inválido sem order_num" do
    assert_not build_modulo(order_num: nil).valid?
  end

  test "order_num deve ser inteiro positivo" do
    assert_not build_modulo(order_num: 0).valid?
    assert_not build_modulo(order_num: -1).valid?
    assert_not build_modulo(order_num: 1.5).valid?
  end

  test "pertence a um course" do
    assert_equal courses(:math_101), modules(:module_one).course
  end

  test "tem muitas aulas" do
    assert_equal 2, modules(:module_one).lessons.count
  end

  test "tem no máximo um quiz" do
    assert_not_nil modules(:module_one).quiz
    assert_nil modules(:module_two).quiz
    assert_nil modules(:module_empty).quiz
  end
end
