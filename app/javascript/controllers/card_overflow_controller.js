import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="card-overflow"
// Shows a bottom fade gradient when the card content overflows its bounded height.
export default class extends Controller {
  static targets = ["content", "fade"]

  connect() {
    this.update()
    this.resizeObserver = new ResizeObserver(() => this.update())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  update() {
    const overflows = this.element.scrollHeight > this.element.clientHeight
    this.fadeTarget.hidden = !overflows
  }
}
