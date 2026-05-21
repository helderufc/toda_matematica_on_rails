class ApplicationController < ActionController::API
  include Paginatable

  rescue_from ActiveRecord::RecordNotFound,   with: :not_found
  rescue_from ActiveRecord::RecordInvalid,    with: :unprocessable_entity

  private

  # Atribui o próximo order_num dentro de `scope` e salva. Sob concorrência, dois
  # inserts podem disputar a mesma posição — o índice único faz o segundo falhar,
  # e aí recalculamos e tentamos de novo.
  def save_with_next_order_num!(record, scope)
    attempts = 0
    begin
      record.order_num = scope.maximum(:order_num).to_i + 1
      record.save!
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      retry if attempts < 3
      raise
    end
  end

  def expire_quiz_cache(module_id)
    Rails.cache.delete(Quiz.cache_key_for_module(module_id))
  end

  def not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def unprocessable_entity(e)
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end
end
