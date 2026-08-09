import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="overflow-indicator"
export default class extends Controller {
  static targets = ["container", "badge", "item"]

  connect() {
    this.update()
    this.resizeObserver = new ResizeObserver(() => this.update())
    this.resizeObserver.observe(this.containerTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  update() {
    const containerRect = this.containerTarget.getBoundingClientRect()
    let hidden = 0
    this.itemTargets.forEach((item) => {
      const itemRect = item.getBoundingClientRect()
      const overflows = itemRect.bottom > containerRect.bottom
      item.hidden = overflows
      if (overflows) hidden++
    })
    if (hidden > 0) {
      this.badgeTarget.textContent = `+${hidden} more`
      this.badgeTarget.hidden = false
    } else {
      this.badgeTarget.hidden = true
    }
  }
}
