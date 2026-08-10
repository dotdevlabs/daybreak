import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="card-overflow"
// Shows a bottom fade gradient when the card content overflows its bounded height.
export default class extends Controller {
  static targets = ["content", "fade"]

  connect() {
    this.update()
    // Observe inner content so font-load reflows (which change content height
    // but not the capped outer card height) trigger a re-check.
    this.resizeObserver = new ResizeObserver(() => this.update())
    this.resizeObserver.observe(this.hasContentTarget ? this.contentTarget : this.element)
    // Re-check after all web fonts finish loading.
    if (document.fonts) {
      document.fonts.ready.then(() => {
        if (this.element.isConnected) this.update()
      })
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  update() {
    const overflows = this.element.scrollHeight > this.element.clientHeight
    this.fadeTarget.hidden = !overflows
  }
}
