class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def service_worker
    response.set_header("Service-Worker-Allowed", "/")
    response.set_header("Content-Type", "application/javascript")
    render template: "pwa/service-worker", layout: false
  end

  def manifest
    render template: "pwa/manifest", layout: false
  end
end
