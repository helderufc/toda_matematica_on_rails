class CoursesController < ApplicationController
  def index
    render json: cached_page("courses", Course.order(:created_at))
  end

  def show
    json = Rails.cache.fetch("courses/#{params[:id]}/show", expires_in: Paginatable::CACHE_TTL) do
      course.as_json
    end
    render json: json
  end

  def create
    c = Course.new(course_params)

    if params[:image].present?
      c.image_path = FileUploadService.save_image(params[:image])
    end

    c.save!
    expire_page_cache("courses")
    render json: c, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def course
    @course ||= Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:title, :category, :description)
  end
end
