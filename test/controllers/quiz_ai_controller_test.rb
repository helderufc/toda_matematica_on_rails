require "test_helper"

class QuizAiControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @modulo       = modules(:module_one)   # tem lesson_one com content_editor; já tem quiz
    @barren       = modules(:module_two)   # só tem lesson_barren (sem conteúdo)
    @fresh        = modules(:module_empty) # sem quiz, sem aulas
  end

  # ---------- gerar ----------

  test "POST quiz/gerar gera quiz e armazena como pendente" do
    post "/modules/#{@modulo.id}/quiz/gerar", as: :json
    assert_response :ok
    assert response.parsed_body.key?("quiz")
    assert_not_nil PendingContentStore.fetch_quiz(@modulo.id)
  end

  test "POST quiz/gerar retorna 422 quando módulo não tem conteúdo legível" do
    post "/modules/#{@barren.id}/quiz/gerar", as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body.key?("error")
  end

  test "POST quiz/gerar retorna 404 para módulo inexistente" do
    post "/modules/0/quiz/gerar", as: :json
    assert_response :not_found
  end

  # ---------- pendente ----------

  test "GET quiz/pendente retorna quiz pendente" do
    PendingContentStore.store_quiz(@modulo.id, [ { "statement" => "Q?" } ])
    get "/modules/#{@modulo.id}/quiz/pendente", as: :json
    assert_response :ok
    assert response.parsed_body.key?("quiz")
  end

  test "GET quiz/pendente retorna 404 quando não há nada pendente" do
    get "/modules/#{@modulo.id}/quiz/pendente", as: :json
    assert_response :not_found
  end

  # ---------- confirmar ----------

  test "POST quiz/confirmar cria quiz a partir dos dados pendentes" do
    quiz_data = [
      {
        "statement" => "Pergunta IA?",
        "points" => 1,
        "order_num" => 1,
        "alternatives" => [
          { "text" => "Certa", "correct" => true },
          { "text" => "Errada", "correct" => false }
        ]
      }
    ]
    PendingContentStore.store_quiz(@fresh.id, quiz_data)

    assert_difference "Quiz.count", 1 do
      post "/modules/#{@fresh.id}/quiz/confirmar", as: :json
    end

    assert_response :created
    assert_nil PendingContentStore.fetch_quiz(@fresh.id)
    body = response.parsed_body
    assert body["questions"].any?
  end

  test "POST quiz/confirmar retorna 422 quando não há pendente" do
    post "/modules/#{@fresh.id}/quiz/confirmar", as: :json
    assert_response :unprocessable_entity
  end

  test "POST quiz/confirmar retorna 422 quando módulo já tem quiz" do
    quiz_data = [ {
      "statement" => "Q?", "points" => 1, "order_num" => 1,
      "alternatives" => [ { "text" => "A", "correct" => true }, { "text" => "B", "correct" => false } ]
    } ]
    PendingContentStore.store_quiz(@modulo.id, quiz_data)
    post "/modules/#{@modulo.id}/quiz/confirmar", as: :json
    assert_response :unprocessable_entity
  end

  # ---------- regerar ----------

  test "POST quiz/regerar sobrescreve conteúdo pendente" do
    PendingContentStore.store_quiz(@modulo.id, [ { "statement" => "Velho" } ])
    post "/modules/#{@modulo.id}/quiz/regerar", as: :json
    assert_response :ok
    novo = PendingContentStore.fetch_quiz(@modulo.id)
    assert_not_nil novo
    assert_not_equal [ { "statement" => "Velho" } ], novo
  end

  test "POST quiz/regerar retorna 422 quando módulo não tem conteúdo legível" do
    post "/modules/#{@barren.id}/quiz/regerar", as: :json
    assert_response :unprocessable_entity
  end
end
