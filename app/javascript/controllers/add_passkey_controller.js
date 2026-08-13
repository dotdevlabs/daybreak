import { Controller } from "@hotwired/stimulus"
import { create } from "@github/webauthn-json"

// Connects to data-controller="add-passkey"
export default class extends Controller {
  static targets = ["error"]
  static values = { challengeUrl: String, saveUrl: String }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }

  async addPasskey() {
    try {
      const optResp = await fetch(this.challengeUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken(), "Content-Type": "application/json" }
      })
      if (!optResp.ok) throw new Error("Failed to get options")
      const options = await optResp.json()

      const credential = await create(options)

      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.saveUrlValue

      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = this.csrfToken()
      form.appendChild(csrfInput)

      const credInput = document.createElement("input")
      credInput.type = "hidden"
      credInput.name = "credential"
      credInput.value = JSON.stringify(credential)
      form.appendChild(credInput)

      document.body.appendChild(form)
      form.submit()
    } catch (e) {
      if (e.name === "NotAllowedError") {
        this.showError("Passkey setup was cancelled.")
      } else {
        this.showError(e.message || "An error occurred.")
      }
    }
  }
}
