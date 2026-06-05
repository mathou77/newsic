import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "confirmation"]

  save(event) {
    event.preventDefault()

    const form = this.buttonTarget.querySelector("form")
    const url = form.action
    const token = document.querySelector("meta[name='csrf-token']").content

    fetch(url, {
      method: "POST",
      headers: { "X-CSRF-Token": token }
    }).then(() => {
      this.buttonTarget.classList.add("d-none")
      this.confirmationTarget.classList.remove("d-none")
    })
  }
}
