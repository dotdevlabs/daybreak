module Api
  class CatalogController < Api::ApplicationController
    def index
      catalog = WidgetCatalog.all
      render_jsonapi(
        data: catalog.map(&:as_jsonapi),
        links: {
          self:  "/api/catalog",
          first: "/api/catalog",
          last:  "/api/catalog",
          prev:  nil,
          next:  nil
        },
        meta: { total_count: catalog.size }
      )
    end
  end
end
