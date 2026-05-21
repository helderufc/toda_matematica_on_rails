class AlternativesController < ApplicationController
  def index
    question = Question.find(params[:question_id])
    render json: Rails.cache.fetch("questions/#{question.id}/alternatives", expires_in: Paginatable::CACHE_TTL) {
      AlternativeSerializer.new(question.alternatives).serialize
    }
  end

  def create
    question = Question.includes(:quiz).find(params[:question_id])
    alt = question.alternatives.new(alternative_params)
    alt.save!
    Rails.cache.delete("questions/#{question.id}/alternatives")
    expire_quiz_cache(question.quiz.module_id)
    render json: AlternativeSerializer.new(alt).serialize, status: :created
  end

  private

  def alternative_params
    params.require(:alternative).permit(:text, :correct)
  end
end
