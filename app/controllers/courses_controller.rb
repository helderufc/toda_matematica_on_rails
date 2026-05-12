class CoursesController < ApplicationController
  def index
    render json: Course.order(:created_at)
  end

  def show
    render json: course
  end

  def create
    c = Course.new(course_params)

    if params[:image].present?
      c.image_path = FileUploadService.save_image(params[:image])
    end

    c.save!
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
