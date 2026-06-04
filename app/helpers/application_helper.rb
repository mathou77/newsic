module ApplicationHelper
  # Renders a user's avatar: their Spotify photo when available, otherwise a
  # gradient disc with their initials.
  def avatar_for(user, size: 48)
    style = "width: #{size}px; height: #{size}px;"

    if user.avatar_url.present?
      image_tag user.avatar_url, class: "avatar-img", style: style, alt: user.display_name
    else
      content_tag :span, user.initials,
                  class: "avatar-fallback",
                  style: "#{style} font-size: #{(size * 0.38).round}px;"
    end
  end
end
