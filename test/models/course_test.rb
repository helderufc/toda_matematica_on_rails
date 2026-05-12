require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "válido com todos os atributos" do
    course = Course.new(title: "Álgebra", category: "Matemática", description: "Intro")
    assert course.valid?
  end

  test "inválido sem title" do
    course = Course.new(category: "Matemática", description: "Intro")
    assert_not course.valid?
    assert course.errors[:title].any?
  end

  test "inválido sem category" do
    course = Course.new(title: "Álgebra", description: "Intro")
    assert_not course.valid?
    assert course.errors[:category].any?
  end

  test "inválido sem description" do
    course = Course.new(title: "Álgebra", category: "Matemática")
    assert_not course.valid?
    assert course.errors[:description].any?
  end

  test "category respeita limite de 100 caracteres" do
    course = Course.new(title: "A", description: "d", category: "x" * 101)
    assert_not course.valid?
    course.category = "x" * 100
    assert course.valid?
  end

  test "tem muitos módulos" do
    assert_equal 2, courses(:math_101).modulos.count
  end

  test "cascade: destruir curso destrói módulos" do
    course = courses(:math_101)
    mod_ids = course.modulos.pluck(:id)
    assert mod_ids.any?
    course.destroy
    assert_equal 0, Modulo.where(id: mod_ids).count
  end
end
