import { Controller } from "@hotwired/stimulus"
import { create, get } from "@github/webauthn-json"

export default class extends Controller {
  static targets = [
    "signupEmail", "signupMethod", "checkEmail", "pendingEmail",
    "signinEmail", "signinEmailInput", "signupEmailInput", "errorMessage"
  ]
  static values = { step: String }

  connect() {
    this.showStep(this.stepValue || "signup-email")
  }

  showStep(step) {
    this.stepValue = step
    const allTargets = ["signupEmail", "signupMethod", "checkEmail", "signinEmail"]
    allTargets.forEach(name => {
      if (this[`has${name.charAt(0).toUpperCase() + name.slice(1)}Target`]) {
        this[`${name}Target`].hidden = true
      }
    })
    this.errorMessageTarget.hidden = true

    const map = {
      "signup-email":  "signupEmail",
      "signup-method": "signupMethod",
      "check-email":   "checkEmail",
      "signin-email":  "signinEmail"
    }
    if (map[step] && this[`has${map[step].charAt(0).toUpperCase() + map[step].slice(1)}Target`]) {
      this[`${map[step]}Target`].hidden = false
    }
  }

  showSignin() { this.showStep("signin-email") }
  showSignup()  { this.showStep("signup-email") }

  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.hidden = false
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  async submitSignupEmail(event) {
    event.preventDefault()
    const email = this.signupEmailInputTarget.value
    try {
      const resp = await fetch("/registration", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ email_address: email })
      })
      const data = await resp.json()
      if (resp.ok) {
        this.showStep("signup-method")
      } else {
        this.showError(data.errors?.join(", ") || data.error || "Registration failed")
      }
    } catch {
      this.showError("Network error. Please try again.")
    }
  }

  async startPasskeyRegistration() {
    try {
      const optResp = await fetch("/webauthn/registration/challenge", {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken(), "Content-Type": "application/json" }
      })
      if (!optResp.ok) throw new Error("Failed to get registration options")
      const options = await optResp.json()

      const credential = await create(options)

      const cbResp = await fetch("/webauthn/registration", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ credential })
      })
      const cbData = await cbResp.json()
      if (cbResp.ok) {
        this.pendingEmailTarget.textContent = cbData.email
        this.showStep("check-email")
      } else {
        this.showError(cbData.error || "Passkey setup failed")
      }
    } catch (e) {
      if (e.name === "NotAllowedError") {
        this.showError("Passkey setup was cancelled.")
      } else if (e.name === "NotSupportedError") {
        this.showError("Passkeys are not supported on this browser.")
      } else {
        this.showError(e.message || "An error occurred.")
      }
    }
  }

  async resendEmail() {
    try {
      await fetch("/email_verification/resend", {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken(), "Content-Type": "application/json" }
      })
    } catch {
      // Silently ignore
    }
  }

  async submitSigninEmail(event) {
    event.preventDefault()
    const email = this.signinEmailInputTarget.value
    try {
      const optResp = await fetch("/webauthn/authentication/challenge", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ email_address: email })
      })
      if (!optResp.ok) throw new Error("Failed to get authentication options")
      const options = await optResp.json()

      const credential = await get(options)

      const cbResp = await fetch("/webauthn/authentication", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ credential, email_address: email })
      })
      const cbData = await cbResp.json()
      if (cbResp.ok && cbData.redirect_url) {
        window.location.href = cbData.redirect_url
      } else if (cbData.error === "not_verified") {
        this.pendingEmailTarget.textContent = cbData.email || email
        this.showStep("check-email")
      } else {
        this.showError(cbData.error || "Sign in failed")
      }
    } catch (e) {
      if (e.name === "NotAllowedError") {
        this.showError("Passkey sign-in was cancelled.")
      } else {
        this.showError(e.message || "An error occurred.")
      }
    }
  }
}
