Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Courses
  resources :courses, only: [ :index, :show, :create ] do
    resources :modules, only: [ :index, :create ]
  end

  # Modules (show standalone + lesson/quiz children)
  resources :modules, only: [ :show ] do
    resources :lessons, only: [ :index, :create ]
    resource  :quiz,    only: [ :show, :create ]

    # Quiz IA
    post "quiz/gerar",     to: "quiz_ai#gerar"
    get  "quiz/pendente",  to: "quiz_ai#pendente"
    post "quiz/confirmar", to: "quiz_ai#confirmar"
    post "quiz/regerar",   to: "quiz_ai#regerar"
  end

  # Lessons (show standalone + IA actions)
  resources :lessons, only: [ :show ] do
    member do
      post "gerar-conteudo",     to: "lesson_ai#gerar"
      get  "conteudo-pendente",  to: "lesson_ai#pendente"
      post "confirmar-conteudo", to: "lesson_ai#confirmar"
      post "regerar-conteudo",   to: "lesson_ai#regerar"
    end
  end

  # Quiz configuration and questions (by quiz id)
  resources :quizzes, only: [] do
    member { post :configurar }
    resources :questions, only: [ :index, :create ]
  end

  # Alternatives (by question id)
  resources :questions, only: [] do
    resources :alternatives, only: [ :index, :create ]
  end
end
