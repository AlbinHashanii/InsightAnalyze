class AddImageUrlController < ApplicationController
  require 'nokogiri'
  require 'open-uri'

  def index(url)
    begin
      document = Nokogiri::HTML(open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))
      image_url = document.css('meta[property="og:image"]')[0]['content'] rescue ''

      return '' if image_url.nil?
      puts "Image URL: #{image_url}"
      image_url
    rescue OpenURI::HTTPError, Net::OpenTimeout => e
      puts "Error: #{e.message}"
      return ''
    end
  end
end
