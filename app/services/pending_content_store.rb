class PendingContentStore
  TTL = 1.hour

  def self.store_lesson(lesson_id, content)
    Rails.cache.write(lesson_key(lesson_id), content, expires_in: TTL)
  end

  def self.fetch_lesson(lesson_id)
    Rails.cache.read(lesson_key(lesson_id))
  end

  def self.clear_lesson(lesson_id)
    Rails.cache.delete(lesson_key(lesson_id))
  end

  def self.store_quiz(module_id, quiz_data)
    Rails.cache.write(quiz_key(module_id), quiz_data, expires_in: TTL)
  end

  def self.fetch_quiz(module_id)
    Rails.cache.read(quiz_key(module_id))
  end

  def self.clear_quiz(module_id)
    Rails.cache.delete(quiz_key(module_id))
  end

  def self.lesson_key(lesson_id) = "pending_lesson:#{lesson_id}"
  def self.quiz_key(module_id)   = "pending_quiz:#{module_id}"
  private_class_method :lesson_key, :quiz_key
end
