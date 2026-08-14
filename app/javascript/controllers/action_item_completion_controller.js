import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    context: String,
    text: String,
    priority: String,
    link: String,
    url: String
  }

  complete() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      context: this.contextValue,
      text: this.textValue,
      priority: this.priorityValue
    }
    if (this.linkValue) body.link = this.linkValue
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify(body)
    })
    this.element.closest(".action-item").classList.add("action-item--completed")
  }
}
