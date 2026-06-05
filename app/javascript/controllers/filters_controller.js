import { Controller } from "@hotwired/stimulus"

// Drives the pill / slider / surprise filter UI by writing hidden inputs in the
// filters form (so the "Start swiping" submit sends the chosen values).
export default class extends Controller {
  pick(event) {
    const btn = event.currentTarget
    const { field, value } = btn.dataset
    const input = this.element.querySelector(`input[name="${field}"]`)
    const group = this.element.querySelectorAll(`.filter-pill[data-field="${field}"]`)
    const wasActive = btn.classList.contains("is-active")

    group.forEach((b) => b.classList.remove("is-active"))

    if (wasActive && btn.dataset.toggle === "true") {
      if (input) input.value = ""
    } else {
      btn.classList.add("is-active")
      if (input) input.value = value
    }
  }

  slide(event) {
    const v = Number(event.currentTarget.value)
    const input = this.element.querySelector('input[name="popularity"]')
    if (input) input.value = v <= 33 ? "mainstream" : v >= 67 ? "hidden" : ""
  }

  surprise(event) {
    const card = event.currentTarget
    const input = this.element.querySelector('input[name="discovery"]')
    const on = card.classList.toggle("is-active")
    if (input) input.value = on ? "1" : ""
  }

  reset() {
    this.element.querySelectorAll(".filter-pill, .surprise-card").forEach((b) => b.classList.remove("is-active"))
    this.element.querySelectorAll('input[type="hidden"]').forEach((i) => { i.value = "" })
    this.element.querySelectorAll('input[type="checkbox"]').forEach((c) => { c.checked = false })
    const slider = this.element.querySelector(".fine-slider")
    if (slider) slider.value = 50
  }
}
