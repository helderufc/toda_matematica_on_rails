class QuestionsController < ApplicationController
  def index
    quiz = Quiz.find(params[:quiz_id])
    render json: cached_page("quizzes/#{quiz.id}/questions", quiz.questions.includes(:alternatives).order(:order_num)) { |s| s.as_json(include: :alternatives) }
  end

  def create
    quiz = Quiz.find(params[:quiz_id])
    q = quiz.questions.new(question_params)
    q.order_num = quiz.questions.maximum(:order_num).to_i + 1

    q.save!
    render json: q.as_json(include: :alternatives), status: :created
  end

  private

  def question_params
    params.require(:question).permit(
      :statement, :points,
      alternatives_attributes: [ :text, :correct ]
    )
  end
end
