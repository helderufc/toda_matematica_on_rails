require "test_helper"

class PendingContentStoreTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }

  test "armazena e recupera conteúdo de aula" do
    PendingContentStore.store_lesson(1, "conteúdo da aula")
    assert_equal "conteúdo da aula", PendingContentStore.fetch_lesson(1)
  end

  test "limpa conteúdo de aula" do
    PendingContentStore.store_lesson(1, "conteúdo")
    PendingContentStore.clear_lesson(1)
    assert_nil PendingContentStore.fetch_lesson(1)
  end

  test "retorna nil para aula sem pendente" do
    assert_nil PendingContentStore.fetch_lesson(99999)
  end

  test "armazena e recupera dados de quiz" do
    data = [ { "statement" => "Q?", "alternatives" => [] } ]
    PendingContentStore.store_quiz(1, data)
    assert_equal data, PendingContentStore.fetch_quiz(1)
  end

  test "limpa dados de quiz" do
    PendingContentStore.store_quiz(1, [ { "statement" => "Q?" } ])
    PendingContentStore.clear_quiz(1)
    assert_nil PendingContentStore.fetch_quiz(1)
  end

  test "retorna nil para quiz sem pendente" do
    assert_nil PendingContentStore.fetch_quiz(99999)
  end

  test "chaves de aula e quiz são independentes" do
    PendingContentStore.store_lesson(42, "aula")
    PendingContentStore.store_quiz(42, [ "quiz" ])
    assert_equal "aula", PendingContentStore.fetch_lesson(42)
    assert_equal [ "quiz" ], PendingContentStore.fetch_quiz(42)
    PendingContentStore.clear_lesson(42)
    assert_nil PendingContentStore.fetch_lesson(42)
    assert_equal [ "quiz" ], PendingContentStore.fetch_quiz(42)
  end

  test "sobrescreve conteúdo de aula existente" do
    PendingContentStore.store_lesson(1, "versão 1")
    PendingContentStore.store_lesson(1, "versão 2")
    assert_equal "versão 2", PendingContentStore.fetch_lesson(1)
  end
end
