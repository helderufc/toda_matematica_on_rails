class QuizzesController < ApplicationController
  QUIZ_CACHE_TTL = 5.minutes

  def show
    json = Rails.cache.fetch(Quiz.cache_key_for_module(params[:module_id]), expires_in: QUIZ_CACHE_TTL) do
      modulo = Modulo.includes(quiz: { questions: :alternatives }).find(params[:module_id])
      modulo.quiz && quiz_json(modulo.quiz)
    end
    return render json: { error: "Quiz não encontrado" }, status: :not_found unless json

    render json: json
  end

  def create
    modulo = Modulo.includes(:quiz).find(params[:module_id])

    if modulo.quiz.present?
      return render json: { error: "Este módulo já possui um quiz" }, status: :unprocessable_entity
    end

    quiz = modulo.build_quiz(quiz_create_params)
    quiz.questions.each_with_index { |q, i| q.order_num = i + 1 }
    quiz.save!
    expire_quiz_cache(modulo.id)
    render json: quiz_json(Quiz.includes(questions: :alternatives).find(quiz.id)), status: :created
  end

  def configurar
    quiz = Quiz.find(params[:id])
    quiz.update!(configurar_params)
    expire_quiz_cache(quiz.module_id)
    render json: quiz
  end

  private

  def quiz_json(quiz)
    quiz.as_json(
      only: %i[id show_wrong_answers show_correct_answers show_points],
      include: {
        questions: {
          only: %i[id statement points order_num],
          include: {
            alternatives: { only: %i[id text correct] }
          }
        }
      }
    )
  end

  def quiz_create_params
    params.require(:quiz).permit(
      :show_wrong_answers, :show_correct_answers, :show_points,
      questions_attributes: [
        :statement, :points,
        alternatives_attributes: [ :text, :correct ]
      ]
    )
  end

  def configurar_params
    params.require(:quiz).permit(:show_wrong_answers, :show_correct_answers, :show_points)
  end
end
