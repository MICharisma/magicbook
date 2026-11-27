import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "option", "empty", "more"]
  static values = { limit: { type: Number, default: 8 } }

  connect() {
    this.expanded = false
    this.sync()
  }

  filter() {
    this.sync()
  }

  showMore(event) {
    event.preventDefault()
    this.expanded = true
    this.sync()
  }

  sync() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""
    const searching = query.length > 0
    const matches = []

    this.optionTargets.forEach((option) => {
      const match = !searching || (option.dataset.label || "").toLowerCase().includes(query)
      if (match) matches.push(option)
      else option.hidden = true
    })

    const revealAll = this.expanded || searching
    matches.forEach((option, index) => {
      option.hidden = !revealAll && index >= this.limitValue
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = matches.length !== 0
    if (this.hasMoreTarget) this.moreTarget.hidden = revealAll || matches.length <= this.limitValue
  }
}
