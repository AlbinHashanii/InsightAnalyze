class AddAuthorController < ApplicationController
  def index(url)
    begin
      document = Nokogiri::HTML(open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))
      author = document.css('meta[name="author"]')[0]['content'] rescue ''

      return '' if author.nil?
      puts "Author: #{author}"
      author
    rescue OpenURI::HTTPError => e
      return ''
    end
  end
end