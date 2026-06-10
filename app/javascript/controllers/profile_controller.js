import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["friends"]

  toggleFriends() {
    this.friendsTarget.classList.toggle("is-open")
  }
}
