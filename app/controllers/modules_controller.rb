class ModulesController < ApplicationController
  def index
    course = Course.find(params[:course_id])
    render json: cached_page("courses/#{course.id}/modules", course.modulos.order(:order_num))
  end

  def show
    render json: modulo if stale?(modulo, public: true)
  end

  def create
    course = Course.find(params[:course_id])
    m = course.modulos.new(modulo_params)

    if params[:image].present?
      m.image_path = FileUploadService.save_image(params[:image])
    end

    save_with_next_order_num!(m, course.modulos)
    expire_page_cache("courses/#{course.id}/modules")
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
