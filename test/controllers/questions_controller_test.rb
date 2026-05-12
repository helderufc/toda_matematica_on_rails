require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  test "GET /quizzes/:id/questions retorna questões com alternativas" do
    get "/quizzes/#{quizzes(:quiz_one).id}/questions", as: :json
    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    assert body.first.key?("alternatives")
  end

  test "GET /quizzes/:id/questions retorna 404 para quiz inexistente" do
    get "/quizzes/0/questions", as: :json
    assert_response :not_found
  end

  test "POST /quizzes/:id/questions cria questão com alternativas e auto-atribui order_num" do
    quiz = quizzes(:quiz_one)
    expected_order = quiz.questions.count + 1

    assert_difference "Question.count", 1 do
      post "/quizzes/#{quiz.id}/questions",
        params: {
          question: {
            statement: "Nova pergunta?",
            points: 2,
            alternatives_attributes: [
              { text: "Certa", correct: true },
              { text: "Errada", correct: false }
            ]
          }
        },
        as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert_equal "Nova pergunta?", body["statement"]
    assert_equal expected_order, body["order_num"]
    assert body["alternatives"].any?
  end

  test "POST /quizzes/:id/questions retorna 422 sem alternativa correta" do
    assert_no_difference "Question.count" do
      post "/quizzes/#{quizzes(:quiz_one).id}/questions",
        params: {
          question: {
            statement: "Q?",
            alternatives_attributes: [
              { text: "A", correct: false },
              { text: "B", correct: false }
            ]
          }
        },
        as: :json
    end
    assert_response :unprocessable_entity
  end

  test "POST /quizzes/:id/questions retorna 422 com só uma alternativa" do
    assert_no_difference "Question.count" do
      post "/quizzes/#{quizzes(:quiz_one).id}/questions",
        params: {
          question: {
            statement: "Q?",
            alternatives_attributes: [ { text: "Única", correct: true } ]
          }
        },
        as: :json
    end
    assert_response :unprocessable_entity
  end
end
