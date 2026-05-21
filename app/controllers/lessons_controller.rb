class LessonsController < ApplicationController
  def index
    modulo = Modulo.find(params[:module_id])
    scope = modulo.lessons.without_content.order(:order_num)
    render json: cached_page("modules/#{modulo.id}/lessons", scope)
  end

  def show
    json = Rails.cache.fetch("lessons/#{params[:id]}/show", expires_in: Paginatable::CACHE_TTL) do
      lesson.as_json
    end
    render json: json
  end

  def create
    modulo = Modulo.find(params[:module_id])
    l = modulo.lessons.new(lesson_params)

    if params[:file].present?
      l.file_path = FileUploadService.save_pdf(params[:file])
      l.file_type = "pdf"
    end

    save_with_next_order_num!(l, modulo.lessons)
    expire_page_cache("modules/#{modulo.id}/lessons")
    render json: l, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def lesson
    @lesson ||= Lesson.find(params[:id])
  end

  def lesson_params
    params.require(:lesson).permit(:name, :content_editor)
  end
end
