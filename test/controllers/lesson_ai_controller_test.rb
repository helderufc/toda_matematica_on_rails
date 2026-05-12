require "test_helper"

class LessonAiControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @lesson = lessons(:lesson_one)  # tem content_editor
    @barren = lessons(:lesson_two)  # sem content_editor e sem file_path
  end

  test "POST gerar-conteudo gera conteúdo e armazena como pendente" do
    post "/lessons/#{@lesson.id}/gerar-conteudo", as: :json
    assert_response :ok
    assert response.parsed_body.key?("content")
    assert_not_nil PendingContentStore.fetch_lesson(@lesson.id)
  end

  test "POST gerar-conteudo retorna 422 quando aula não tem conteúdo nem arquivo" do
    post "/lessons/#{@barren.id}/gerar-conteudo", as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body.key?("error")
  end

  test "POST gerar-conteudo retorna 404 para aula inexistente" do
    post "/lessons/0/gerar-conteudo", as: :json
    assert_response :not_found
  end

  test "GET conteudo-pendente retorna conteúdo quando existe" do
    PendingContentStore.store_lesson(@lesson.id, "Conteúdo gerado")
    get "/lessons/#{@lesson.id}/conteudo-pendente", as: :json
    assert_response :ok
    assert_equal "Conteúdo gerado", response.parsed_body["content"]
  end

  test "GET conteudo-pendente retorna 404 quando não há nada pendente" do
    get "/lessons/#{@lesson.id}/conteudo-pendente", as: :json
    assert_response :not_found
  end

  test "POST confirmar-conteudo persiste e limpa pendente" do
    PendingContentStore.store_lesson(@lesson.id, "Conteúdo confirmado")
    post "/lessons/#{@lesson.id}/confirmar-conteudo", as: :json
    assert_response :ok
    assert_equal "Conteúdo confirmado", @lesson.reload.content_editor
    assert_nil PendingContentStore.fetch_lesson(@lesson.id)
  end

  test "POST confirmar-conteudo retorna 422 quando não há pendente" do
    post "/lessons/#{@lesson.id}/confirmar-conteudo", as: :json
    assert_response :unprocessable_entity
  end

  test "POST regerar-conteudo sobrescreve conteúdo pendente" do
    PendingContentStore.store_lesson(@lesson.id, "Conteúdo antigo")
    post "/lessons/#{@lesson.id}/regerar-conteudo", as: :json
    assert_response :ok
    novo = PendingContentStore.fetch_lesson(@lesson.id)
    assert_not_nil novo
    assert_not_equal "Conteúdo antigo", novo
  end

  test "POST regerar-conteudo retorna 422 quando aula não tem fonte" do
    post "/lessons/#{@barren.id}/regerar-conteudo", as: :json
    assert_response :unprocessable_entity
  end
end
