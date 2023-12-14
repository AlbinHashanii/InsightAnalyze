# frozen_string_literal: true

class RssParserController < ApplicationController
  def index

    require 'mechanize'
    require 'nokogiri'
    require 'open-uri'

    # Create a new Mechanize agent
    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    rss_items = []
    sources = Source.all + FactCheckingSource.all

    # Specify the URL you want to crawl
    sources.each do |source|
      xml_content = agent.get(source.url).body
      classification = source.trust_type
      xml_doc = Nokogiri::XML(xml_content)

      items = xml_doc.xpath('//item')
      if items.nil?
        items = xml_doc.css('item')
      end

      puts "*********************** Crawling from #{source.name} ********************"

      # Iterate through each <item> element and extract required data
      items.each do |item|

        link = item.at_xpath('link').text
        if TrustItem.find_by(url: link)
          puts "************************** Item already exists ***************************"
          next
        end

        title = item.at_xpath('title').text
        # Check for clickbait
        similar_words_array = []
        ClickbaitPattern.all.each do |cb|
          similar_words_array << similar_words(title, cb.pattern)
        end

        total_unique_similar_words = similar_words_array.flatten.uniq.size
        if total_unique_similar_words.present?
          if total_unique_similar_words >= 3
            classification = 'Clickbait'
          else
            classification = source.trust_type
          end
        end

        body = item.at_xpath('description').text
        content = ''
        author = ''
        # Attempt to extract content; set to empty string if an error occurs
        begin
          content = item.at_xpath('content:encoded', 'content' => 'http://purl.org/rss/1.0/modules/content/').text
          author = item.at_xpath('dc:creator', 'dc' => 'http://purl.org/dc/elements/1.1/').text
        rescue StandardError => e
          puts "Error extracting content: #{e.message}"
        end

        pub_date_node = item.at_xpath('pubDate')
        if pub_date_node
          pub_date = pub_date_node.text
        else
          pub_date = ''
        end

        # Extract the text content without HTML tags from body and content
        body_text = Nokogiri::HTML(body).text
        content_text = Nokogiri::HTML(content).text
        if link.present?
          image_url = AddImageUrlController.new.index(link)
        end

        if author.blank?
          author = AddAuthorController.new.index(link)
        end

        if author.blank?
          author = link.match(/^(https?:\/\/)?(?:www\.)?([a-zA-Z0-9.-]+)\//)&.[](2)
        end

        # Check if the same article is present somewhere
        TrustItem.all.each do |trust_item|
          similarity_score = jaccard_similarity(trust_item.title, title)

          if similarity_score > 0.56
            # Convert date strings to DateTime objects
            trust_item_date = DateTime.parse(trust_item.pub_date.to_s) if trust_item.pub_date.present?
            pub_date_object = DateTime.parse(pub_date.to_s) if pub_date.present?
            date_difference = ''

            if trust_item_date.present? && pub_date_object.present?
              date_difference = trust_item_date - pub_date_object
            elsif
              date_difference = ''
            end


            unless  date_difference = ''
              if date_difference < 0
                FastestSource.create(source: trust_item.source)
              elsif date_difference > 0
                FastestSource.create(source: source.name)
              end
            end
          end
        end

        # Create a hash for the current RSS item
        rss_item = {
          title: title,
          url: link,
          body: body_text,
          content: content_text,
          author: author,
          pub_date: pub_date,
          image_url: image_url,
          source: source.name,
          classification: classification
        }

        # Add the current RSS item to the array
        rss_items << rss_item

        puts " ------------------------------------ Moving to next source ----------------------------------"
      end
    end


    rss_items.each do |rss_item|
      TrustItem.create(
        title: rss_item[:title],
        url: rss_item[:url],
        text: rss_item[:body],
        content: rss_item[:content],
        author: rss_item[:author],
        pub_date: rss_item[:pub_date],
        image_url: rss_item[:image_url],
        source: rss_item[:source],
        classification: rss_item[:classification]
      )
    end
  end

  private
  def count_similar_words(text1, text2)
    words1 = text1.downcase.scan(/[^\s]+/)
    words2 = text2.downcase.scan(/[^\s]+/)

    count = words1.count { |word1| words2.include?(word1) && word1.length > 3 }
  end

  def similar_words(text1, text2)
    words1 = text1.downcase.scan(/[^\s]+/)
    words2 = text2.downcase.scan(/[^\s]+/)

    similar_words = words1.select { |word1| words2.include?(word1) && word1.length > 3 }
  end

  def jaccard_similarity(str1, str2)
    words1 = str1.downcase.scan(/[^\s]+/).map { |word| word.gsub(/[,.!]/, '') }
    words2 = str2.downcase.scan(/[^\s]+/).map { |word| word.gsub(/[,.!]/, '') }
    intersection = (words1 & words2).size.to_f
    union = (words1 | words2).size.to_f
    return 0.0 if union.zero?

    intersection / union
  end

end
