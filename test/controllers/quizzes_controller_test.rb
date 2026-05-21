require "test_helper"

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  def valid_quiz_params(mod_id = nil)
    {
      quiz: {
        show_correct_answers: false,
        show_points: false,
        show_wrong_answers: false,
        questions_attributes: [
          {
            statement: "Qual é 2+2?",
            points: 1,
            alternatives_attributes: [
              { text: "4", correct: true },
              { text: "5", correct: false }
            ]
          }
        ]
      }
    }
  end

  test "GET /modules/:id/quiz retorna quiz com questões e alternativas" do
    get "/modules/#{modules(:module_one).id}/quiz", as: :json
    assert_response :ok
    body = response.parsed_body
    assert body.key?("questions")
    assert_kind_of Array, body["questions"]
  end

  test "GET /modules/:id/quiz retorna 404 quando módulo não tem quiz" do
    get "/modules/#{modules(:module_two).id}/quiz", as: :json
    assert_response :not_found
  end

  test "POST /modules/:id/quiz cria quiz com questões" do
    assert_difference "Quiz.count", 1 do
      post "/modules/#{modules(:module_two).id}/quiz",
        params: valid_quiz_params,
        as: :json
    end
    assert_response :created
    body = response.parsed_body
    assert body["questions"].any?
    assert_equal 1, body["questions"].first["order_num"]
  end

  test "POST /modules/:id/quiz retorna 422 quando módulo já tem quiz" do
    assert_no_difference "Quiz.count" do
      post "/modules/#{modules(:module_one).id}/quiz",
        params: valid_quiz_params,
        as: :json
    end
    assert_response :unprocessable_entity
  end

  test "POST /quizzes/:id/configurar atualiza configurações do quiz" do
    quiz = quizzes(:quiz_one)
    post "/quizzes/#{quiz.id}/configurar",
      params: { quiz: { show_correct_answers: true, show_points: true, show_wrong_answers: true } },
      as: :json

    assert_response :ok
    body = response.parsed_body
    assert body["show_correct_answers"]
    assert body["show_points"]
    assert body["show_wrong_answers"]
  end

  test "POST /quizzes/:id/configurar retorna 404 para quiz inexistente" do
    post "/quizzes/0/configurar",
      params: { quiz: { show_correct_answers: true } },
      as: :json
    assert_response :not_found
  end

  test "GET /modules/:id/quiz reflete questão adicionada (cache invalidado)" do
    mod_id = modules(:module_one).id
    quiz   = quizzes(:quiz_one)

    get "/modules/#{mod_id}/quiz", as: :json
    before = response.parsed_body["questions"].size

    post "/quizzes/#{quiz.id}/questions",
      params: { question: { statement: "Quanto é 5-2?", points: 1,
        alternatives_attributes: [ { text: "3", correct: true }, { text: "4", correct: false } ] } },
      as: :json
    assert_response :created

    get "/modules/#{mod_id}/quiz", as: :json
    assert_equal before + 1, response.parsed_body["questions"].size
  end
end
