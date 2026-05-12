require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  test "GET /modules/:id/lessons retorna aulas ordenadas por order_num" do
    get "/modules/#{modules(:module_one).id}/lessons", as: :json
    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    order_nums = body.map { |l| l["order_num"] }
    assert_equal order_nums.sort, order_nums
  end

  test "GET /modules/:id/lessons retorna 404 para módulo inexistente" do
    get "/modules/0/lessons", as: :json
    assert_response :not_found
  end

  test "GET /lessons/:id retorna a aula" do
    get "/lessons/#{lessons(:lesson_one).id}", as: :json
    assert_response :ok
    assert_equal lessons(:lesson_one).name, response.parsed_body["name"]
  end

  test "GET /lessons/:id retorna 404 para aula inexistente" do
    get "/lessons/0", as: :json
    assert_response :not_found
  end

  test "POST /modules/:id/lessons cria aula e auto-atribui order_num" do
    mod = modules(:module_one)
    expected_order = mod.lessons.count + 1

    assert_difference "Lesson.count", 1 do
      post "/modules/#{mod.id}/lessons",
        params: { lesson: { name: "Nova Aula", content_editor: "Conteúdo" } },
        as: :json
    end

    assert_response :created
    assert_equal expected_order, response.parsed_body["order_num"]
    assert_equal "Nova Aula", response.parsed_body["name"]
  end

  test "POST /modules/:id/lessons retorna 422 com name vazio" do
    assert_no_difference "Lesson.count" do
      post "/modules/#{modules(:module_one).id}/lessons",
        params: { lesson: { name: "" } },
        as: :json
    end
    assert_response :unprocessable_entity
  end
end
