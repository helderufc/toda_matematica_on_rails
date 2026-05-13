class ModulesController < ApplicationController
  def index
    course = Course.find(params[:course_id])
    render json: cached_page("courses/#{course.id}/modules", course.modulos.order(:order_num))
  end

  def show
    render json: modulo
  end

  def create
    course = Course.find(params[:course_id])
    m = course.modulos.new(modulo_params)
    m.order_num = course.modulos.maximum(:order_num).to_i + 1

    if params[:image].present?
      m.image_path = FileUploadService.save_image(params[:image])
    end

    m.save!
    render json: m, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def modulo
    @modulo ||= Modulo.find(params[:id])
  end

  def modulo_params
    params.require(:modulo).permit(:name)
  end
end
