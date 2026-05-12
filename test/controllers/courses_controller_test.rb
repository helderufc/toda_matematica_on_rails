require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  test "GET /courses retorna todos os cursos" do
    get "/courses", as: :json
    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    assert body.any? { |c| c["title"] == courses(:math_101).title }
  end

  test "GET /courses/:id retorna o curso" do
    get "/courses/#{courses(:math_101).id}", as: :json
    assert_response :ok
    assert_equal courses(:math_101).title, response.parsed_body["title"]
  end

  test "GET /courses/:id retorna 404 para curso inexistente" do
    get "/courses/0", as: :json
    assert_response :not_found
  end

  test "POST /courses cria curso com params válidos" do
    assert_difference "Course.count", 1 do
      post "/courses",
        params: { course: { title: "Novo Curso", category: "Geometria", description: "Desc" } },
        as: :json
    end
    assert_response :created
    assert_equal "Novo Curso", response.parsed_body["title"]
    assert_equal "Geometria", response.parsed_body["category"]
  end

  test "POST /courses retorna 422 com title vazio" do
    assert_no_difference "Course.count" do
      post "/courses",
        params: { course: { title: "", category: "Math", description: "d" } },
        as: :json
    end
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  test "POST /courses retorna 422 com category acima de 100 chars" do
    assert_no_difference "Course.count" do
      post "/courses",
        params: { course: { title: "Curso", category: "x" * 101, description: "d" } },
        as: :json
    end
    assert_response :unprocessable_entity
  end
end
