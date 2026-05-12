class QuizzesController < ApplicationController
  def show
    modulo = Modulo.includes(quiz: { questions: :alternatives }).find(params[:module_id])
    quiz = modulo.quiz
    return render json: { error: "Quiz não encontrado" }, status: :not_found unless quiz

    render json: quiz_json(quiz)
  end

  def create
    modulo = Modulo.find(params[:module_id])

    if modulo.quiz.present?
      return render json: { error: "Este módulo já possui um quiz" }, status: :unprocessable_entity
    end

    quiz = modulo.build_quiz(quiz_create_params)
    quiz.questions.each_with_index { |q, i| q.order_num = i + 1 }
    quiz.save!
    render json: quiz_json(Quiz.includes(questions: :alternatives).find(quiz.id)), status: :created
  end

  def configurar
    quiz = Quiz.find(params[:id])
    quiz.update!(configurar_params)
    render json: quiz
  end

  private

  def quiz_json(quiz)
    quiz.as_json(include: { questions: { include: :alternatives } })
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
