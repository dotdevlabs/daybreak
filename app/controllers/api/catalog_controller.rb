module Api
  class CatalogController < Api::ApplicationController
    def index
      render_jsonapi(data: WidgetCatalog.all.map(&:as_jsonapi))
    end
  end
end
