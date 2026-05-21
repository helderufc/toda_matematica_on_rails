class AlternativesController < ApplicationController
  def index
    question = Question.find(params[:question_id])
    render json: cached_page("questions/#{question.id}/alternatives", question.alternatives)
  end

  def create
    question = Question.find(params[:question_id])
    alt = question.alternatives.new(alternative_params)
    alt.save!
    expire_page_cache("questions/#{question.id}/alternatives")
    expire_quiz_cache(question.quiz.module_id)
    render json: alt, status: :created
  end

  private

  def alternative_params
    params.require(:alternative).permit(:text, :correct)
  end
end
