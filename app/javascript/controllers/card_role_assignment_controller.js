import { Controller } from "@hotwired/stimulus"
import { track } from "../analytics"

export default class extends Controller {
  static values = { url: String }
  static targets = ["role"]

  connect() {
    this.dragging = false
  }

  startDrag(event) {
    this.dragging = true
    event.dataTransfer.effectAllowed = "copy"
    event.dataTransfer.setData("text/plain", "card-role")
  }

  endDrag() {
    this.dragging = false
    this.roleTargets.forEach((role) => role.classList.remove("is-dragging-over"))
  }

  allowDrop(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  enterDrop(event) {
    event.preventDefault()
    event.currentTarget.classList.add("is-dragging-over")
  }

  leaveDrop(event) {
    event.currentTarget.classList.remove("is-dragging-over")
  }

  drop(event) {
    event.preventDefault()
    const role = event.currentTarget
    role.classList.remove("is-dragging-over")
    this.assign(role)
  }

  chooseRole(event) {
    this.assign(event.currentTarget)
  }

  async assign(role) {
    if (role.classList.contains("is-assigned") || role.classList.contains("is-saving")) return

    role.classList.add("is-saving")

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify({ card_function_assignment: { card_function_id: role.dataset.roleId } })
      })

      if (!response.ok) throw new Error("Could not save the card role")

      role.classList.add("is-assigned")
      role.setAttribute("aria-pressed", "true")
      role.querySelector(".card-role-status").textContent = "Assigned"
      track("card_role_assigned", { role_id: role.dataset.roleId })
    } catch (_error) {
      role.querySelector(".card-role-status").textContent = "Try again"
    } finally {
      role.classList.remove("is-saving")
    }
  }
}
