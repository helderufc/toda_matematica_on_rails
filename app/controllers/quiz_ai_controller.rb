class QuizAiController < ApplicationController
  def gerar
    quiz_data = AiService.generate_quiz(
      lessons:   modulo.lessons.order(:order_num),
      quantidade: params.fetch(:quantidade, 5).to_i
    )
    PendingContentStore.store_quiz(modulo.id, quiz_data)
    render json: { quiz: quiz_data }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def pendente
    quiz_data = PendingContentStore.fetch_quiz(modulo.id)
    return render json: { error: "Nenhum quiz pendente" }, status: :not_found if quiz_data.nil?

    render json: { quiz: quiz_data }
  end

  def confirmar
    quiz_data = PendingContentStore.fetch_quiz(modulo.id)
    return render json: { error: "Nenhum quiz pendente para confirmar" }, status: :unprocessable_entity if quiz_data.nil?

    if modulo.quiz.present?
      return render json: { error: "Este módulo já possui um quiz" }, status: :unprocessable_entity
    end

    questions_attrs = quiz_data.map do |q|
      q.merge("alternatives_attributes" => q.delete("alternatives") || q.delete(:alternatives) || [])
        .except("alternatives", :alternatives)
    end

    quiz = modulo.build_quiz(questions_attributes: questions_attrs)
    quiz.save!
    PendingContentStore.clear_quiz(modulo.id)
    render json: Quiz.includes(questions: :alternatives).find(quiz.id).as_json(include: { questions: { include: :alternatives } }), status: :created
  end

  def regerar
    quiz_data = AiService.generate_quiz(
      lessons:   modulo.lessons.order(:order_num),
      quantidade: params.fetch(:quantidade, 5).to_i
    )
    PendingContentStore.store_quiz(modulo.id, quiz_data)
    render json: { quiz: quiz_data }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def modulo
    @modulo ||= Modulo.find(params[:module_id])
  end
end
