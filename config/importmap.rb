# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "lucide", to: "https://esm.sh/lucide@0.525.0/dist/esm/lucide.js"
pin "@github/webauthn-json", to: "https://esm.sh/@github/webauthn-json@0.10.5/dist/main/webauthn-json.js"
