require "test_helper"

class ModulesControllerTest < ActionDispatch::IntegrationTest
  test "GET /courses/:id/modules retorna módulos ordenados por order_num" do
    get "/courses/#{courses(:math_101).id}/modules", as: :json
    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    order_nums = body.map { |m| m["order_num"] }
    assert_equal order_nums.sort, order_nums
  end

  test "GET /courses/:id/modules retorna 404 para curso inexistente" do
    get "/courses/0/modules", as: :json
    assert_response :not_found
  end

  test "GET /modules/:id retorna o módulo" do
    get "/modules/#{modules(:module_one).id}", as: :json
    assert_response :ok
    assert_equal "Módulo 1", response.parsed_body["name"]
  end

  test "GET /modules/:id retorna 404 para módulo inexistente" do
    get "/modules/0", as: :json
    assert_response :not_found
  end

  test "POST /courses/:id/modules cria módulo e auto-atribui order_num" do
    course = courses(:math_101)
    expected_order = course.modulos.count + 1

    assert_difference "Modulo.count", 1 do
      post "/courses/#{course.id}/modules",
        params: { modulo: { name: "Novo Módulo" } },
        as: :json
    end

    assert_response :created
    assert_equal expected_order, response.parsed_body["order_num"]
  end

  test "POST /courses/:id/modules retorna 422 com name vazio" do
    assert_no_difference "Modulo.count" do
      post "/courses/#{courses(:math_101).id}/modules",
        params: { modulo: { name: "" } },
        as: :json
    end
    assert_response :unprocessable_entity
  end

  test "POST /courses/:id/modules retorna 404 para curso inexistente" do
    post "/courses/0/modules", params: { modulo: { name: "M" } }, as: :json
    assert_response :not_found
  end
end
