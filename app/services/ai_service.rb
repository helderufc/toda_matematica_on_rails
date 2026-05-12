class AiService
  # Stub — substitua pela integração real (Anthropic, OpenAI, etc.)

  def self.generate_lesson_content(text: nil, pdf_path: nil)
    source = text.presence || (pdf_path ? File.basename(pdf_path) : nil)
    raise ArgumentError, "Nenhum conteúdo disponível para gerar" if source.nil?

    "[STUB] Conteúdo gerado pela IA a partir de: #{source}"
  end

  def self.generate_quiz(lessons:, quantidade: 5)
    readable = lessons.filter_map { |l| l.content_editor.presence || l.file_path }
    raise ArgumentError, "Nenhum conteúdo legível nas aulas do módulo" if readable.empty?

    quantidade.times.map.with_index(1) do |_, i|
      {
        statement: "[STUB] Pergunta #{i} gerada pela IA",
        points: 1,
        order_num: i,
        alternatives: [
          { text: "Alternativa A (correta)", correct: true },
          { text: "Alternativa B", correct: false },
          { text: "Alternativa C", correct: false }
        ]
      }
    end
  end
end
