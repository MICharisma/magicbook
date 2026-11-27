import { Controller } from "@hotwired/stimulus"
import { track } from "../analytics"

export default class extends Controller {
  static targets = ["button", "panel"]

  toggle(event) {
    event.preventDefault()
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.toggle("hidden")
    const open = !this.panelTarget.classList.contains("hidden")
    this.element.classList.toggle("is-open", open)
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", open)
    if (open) track("tag_panel_opened")
  }
}
