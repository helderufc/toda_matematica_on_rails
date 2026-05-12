require "test_helper"

class AlternativesControllerTest < ActionDispatch::IntegrationTest
  test "GET /questions/:id/alternatives retorna alternativas" do
    get "/questions/#{questions(:question_one).id}/alternatives", as: :json
    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    assert_equal 3, body.size
  end

  test "GET /questions/:id/alternatives retorna 404 para questão inexistente" do
    get "/questions/0/alternatives", as: :json
    assert_response :not_found
  end

  test "POST /questions/:id/alternatives cria alternativa errada" do
    assert_difference "Alternative.count", 1 do
      post "/questions/#{questions(:question_two).id}/alternatives",
        params: { alternative: { text: "Nova errada", correct: false } },
        as: :json
    end
    assert_response :created
    assert_equal "Nova errada", response.parsed_body["text"]
    assert_equal false, response.parsed_body["correct"]
  end

  test "POST /questions/:id/alternatives retorna 422 ao adicionar segunda correta" do
    # question_one já tem alt_a_correct (correct: true) no banco
    assert_no_difference "Alternative.count" do
      post "/questions/#{questions(:question_one).id}/alternatives",
        params: { alternative: { text: "Segunda correta", correct: true } },
        as: :json
    end
    assert_response :unprocessable_entity
  end

  test "POST /questions/:id/alternatives retorna 422 sem text" do
    assert_no_difference "Alternative.count" do
      post "/questions/#{questions(:question_one).id}/alternatives",
        params: { alternative: { text: "", correct: false } },
        as: :json
    end
    assert_response :unprocessable_entity
  end
end
