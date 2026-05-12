module Paginatable
  extend ActiveSupport::Concern

  PER_PAGE  = 20
  CACHE_TTL = 30.seconds

  # Uncached pagination — returns an AR relation (headers always set).
  def paginate(scope)
    page  = [params.fetch(:page, 1).to_i, 1].max
    total = scope.except(:includes, :order).count
    set_pagination_headers(total, page)
    scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  # Cached pagination — stores { total:, json: } in Rails.cache (Redis in prod).
  # Pass a block to customise serialisation (e.g. as_json with includes).
  # Cache key format: "<ns>/p<page>"
  def cached_page(cache_ns, scope, &serializer)
    page = [params.fetch(:page, 1).to_i, 1].max

    result = Rails.cache.fetch("#{cache_ns}/p#{page}", expires_in: CACHE_TTL) do
      paged = scope.offset((page - 1) * PER_PAGE).limit(PER_PAGE)
      {
        total: scope.except(:includes, :order).count,
        json:  serializer ? serializer.call(paged) : paged.as_json
      }
    end

    set_pagination_headers(result[:total], page)
    result[:json]
  end

  private

  def set_pagination_headers(total, page)
    response.set_header("X-Total-Count", total.to_s)
    response.set_header("X-Page",        page.to_s)
    response.set_header("X-Per-Page",    PER_PAGE.to_s)
    response.set_header("X-Total-Pages", [(total.to_f / PER_PAGE).ceil, 1].max.to_s)
  end
end
