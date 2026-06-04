import { Controller } from "@hotwired/stimulus"

// Live search: debounce-submits the form as the user types so results update
// without pressing Enter. The form targets a turbo-frame, so only the results
// refresh and the input keeps focus.
export default class extends Controller {
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), 300)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
