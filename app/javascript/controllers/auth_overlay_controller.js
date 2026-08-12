import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loginPane", "registerPane", "loginTab", "registerTab"]
  static values = { mode: String }

  connect() {
    this.applyMode(this.modeValue || "login")
  }

  showLogin() {
    this.applyMode("login")
  }

  showRegister() {
    this.applyMode("register")
  }

  applyMode(mode) {
    const isLogin = mode === "login"
    this.loginPaneTarget.hidden = !isLogin
    this.registerPaneTarget.hidden = isLogin
    this.loginTabTarget.setAttribute("aria-selected", isLogin)
    this.registerTabTarget.setAttribute("aria-selected", !isLogin)
  }
}
