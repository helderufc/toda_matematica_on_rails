class QuestionsController < ApplicationController
  def index
    quiz = Quiz.find(params[:quiz_id])
    render json: quiz.questions.order(:order_num).as_json(include: :alternatives)
  end

  def create
    quiz = Quiz.find(params[:quiz_id])
    q = quiz.questions.new(question_params)
    q.order_num = quiz.questions.count + 1

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
