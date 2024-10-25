module ApplicationHelper
  def icon(icon_class, &)
    content_tag(:i, "", class: "bi bi-#{icon_class}", &)
  end
end
