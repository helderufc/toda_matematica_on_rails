# Prosopite detecta N+1 queries. O gem só é carregado em desenvolvimento e teste.
# Por padrão apenas registra os N+1 no log; rode com PROSOPITE_RAISE=1 para falhar.
if defined?(Prosopite)
  Rails.application.config.after_initialize do
    Prosopite.rails_logger = true
    Prosopite.raise = ENV["PROSOPITE_RAISE"].present?
  end
end
