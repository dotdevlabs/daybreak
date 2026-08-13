import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="credential-rename"
export default class extends Controller {
  static targets = ["display", "form", "input"]

  startEdit() {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.focus()
  }

  cancelEdit() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
