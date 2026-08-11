import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clock"
export default class extends Controller {
  static targets = ["time", "ampm", "greeting", "date"]
  static values = {
    userName: String,
    locale: String,
    greetingMorning: String,
    greetingAfternoon: String,
    greetingEvening: String
  }

  connect() {
    this.update()
    this.timer = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  update() {
    const now = new Date()
    const h24 = now.getHours()
    const mins = now.getMinutes().toString().padStart(2, "0")
    const h12 = ((h24 % 12) || 12).toString().padStart(2, "0")
    const ampm = h24 < 12 ? "AM" : "PM"
    const greetings = [
      this.greetingMorningValue || "Good morning",
      this.greetingAfternoonValue || "Good afternoon",
      this.greetingEveningValue || "Good evening"
    ]
    const greeting = h24 < 12 ? greetings[0] : h24 < 17 ? greetings[1] : greetings[2]
    const name = this.userNameValue
    const locale = this.localeValue || "en"
    const fullDate = now.toLocaleDateString(locale.replace("_", "-"), {
      weekday: "long", month: "long", day: "numeric", year: "numeric"
    })

    if (this.hasTimeTarget) this.timeTarget.textContent = `${h12}:${mins}`
    if (this.hasAmpmTarget) this.ampmTarget.textContent = ampm
    if (this.hasGreetingTarget) this.greetingTarget.textContent = name ? `${greeting}, ${name}` : greeting
    if (this.hasDateTarget) this.dateTarget.textContent = fullDate
  }
}
