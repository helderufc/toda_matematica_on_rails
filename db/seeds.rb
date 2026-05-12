course = Course.find_or_create_by!(title: "Álgebra Linear") do |c|
  c.category    = "Matemática"
  c.description = "Fundamentos de álgebra linear para o ensino médio e superior."
end

modulo = course.modulos.find_or_create_by!(name: "Vetores") do |m|
  m.order_num = 1
end

modulo.lessons.find_or_create_by!(name: "Introdução a Vetores") do |l|
  l.order_num      = 1
  l.content_editor = "Um vetor é definido por magnitude, direção e sentido."
end
