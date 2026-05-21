class LessonAiController < ApplicationController
  def gerar
    content = AiService.generate_lesson_content(
      text:     lesson.content_editor,
      pdf_path: lesson.file_path
    )
    PendingContentStore.store_lesson(lesson.id, content)
    render json: { content: content }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def pendente
    content = PendingContentStore.fetch_lesson(lesson.id)
    return render json: { error: "Nenhum conteúdo pendente" }, status: :not_found if content.nil?

    render json: { content: content }
  end

  def confirmar
    content = PendingContentStore.fetch_lesson(lesson.id)
    return render json: { error: "Nenhum conteúdo pendente para confirmar" }, status: :unprocessable_entity if content.nil?

    lesson.update!(content_editor: content)
    PendingContentStore.clear_lesson(lesson.id)
    Rails.cache.delete("lessons/#{lesson.id}/show")
    render json: lesson
  end

  def regerar
    content = AiService.generate_lesson_content(
      text:     lesson.content_editor,
      pdf_path: lesson.file_path
    )
    PendingContentStore.store_lesson(lesson.id, content)
    render json: { content: content }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def lesson
    @lesson ||= Lesson.find(params[:id])
  end
end
