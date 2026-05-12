class LessonsController < ApplicationController
  def index
    modulo = Modulo.find(params[:module_id])
    render json: modulo.lessons.order(:order_num)
  end

  def show
    render json: lesson
  end

  def create
    modulo = Modulo.find(params[:module_id])
    l = modulo.lessons.new(lesson_params)
    l.order_num = modulo.lessons.count + 1

    if params[:file].present?
      l.file_path = FileUploadService.save_pdf(params[:file])
      l.file_type = "pdf"
    end

    l.save!
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
