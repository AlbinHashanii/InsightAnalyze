# app/helpers/items_helper.rb

module ItemsHelper
  def background_color(classification)
    case classification
    when 'true'
      '#C8E6C9' # Green
    when 'false'
      '#FFCDD2' # Red
    when 'Clickbait'
      '#FFFFCC' # Yellow
    else
      '#ffffff' # Default color
    end
  end
end
