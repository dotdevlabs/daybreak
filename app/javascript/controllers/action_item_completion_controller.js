import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    context: String,
    text: String,
    priority: String,
    url: String
  }

  complete() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({
        context: this.contextValue,
        text: this.textValue,
        priority: this.priorityValue
      })
    })
    this.element.closest(".action-item").classList.add("action-item--completed")
  }
}
