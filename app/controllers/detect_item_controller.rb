class DetectItemController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  require 'mechanize'
  require 'similarity'

  def index
    url = params[:url]

    # Try Nokogiri and OpenURI first
    document = fetch_with_nokogiri(url) || fetch_with_mechanize(url)

    if document
      link = find_element(document, ['link'])
      title = find_element(document, ['title'])
      body = find_element(document, ['meta[name="description"]', 'meta[property="og:description"]'])
      content = find_element(document, ['article'])
      author = find_attribute(document, ['meta[name="author"]'], 'content')
      publication_date = find_attribute(document, ['meta[property="article:published_time"]'], 'content')
      image_url = find_attribute(document, ['meta[property="og:image"]'], 'content')

      similarity_count = 0
      pattern_id = nil

      ClickbaitPattern.all.each do |cb|
        current_similarity_count = count_similar_words(title, cb.pattern)

        if current_similarity_count.positive? && (pattern_id.nil? || current_similarity_count > similarity_count)
          # Update similarity_count and pattern_id if the current pattern has a higher count
          similarity_count = current_similarity_count
          pattern_id = cb.id
        end
      end

      similar_words_array = []
      ClickbaitPattern.all.each do |cb|
        similar_words_array << similar_words(title, cb.pattern)
      end

      total_unique_similar_words = similar_words_array.flatten.uniq.size

      item = {
        title: title.present? ? title.strip : '',
        body: body&.strip || '',
        url: url,
        content: content&.strip || '',
        author: author&.strip || '',
        publication_date: publication_date&.strip || '',
        image_url: image_url&.strip || ''
      }

      # **************************************************************
      # ***************** Clickbait > Fake News **********************
      # **************************************************************



      # **************************************************************
      # ***************** Check for Clickbait ************************
      # **************************************************************

      if total_unique_similar_words.present?
        if total_unique_similar_words >= 3
          source = item[:url].match(/^(https?:\/\/)?(?:www\.)?([a-zA-Z0-9.-]+)\//)&.[](2)
          cp = ClickbaitPattern.new(pattern: title)
          new_item = Item.new(title: item[:title], text: item[:body], author: item[:author],
                              url: item[:url], classification: 'Clickbait', pub_date: item[:publication_date],
                              user_id: User.first.id,content: item[:content], image_url: item[:image_url], source: source)
         cp.save
          if new_item.save
            puts "Saved new item"
            flash[:success] = 'Clickbait found'
            redirect_to items_path
          end
        end
      elsif title.present? && TrustItem.find_by(title: title)
        puts "*************************** Kopje totale ****************************"
      end




      if title.present?
        score = 6
        max_similarity = 0.0
        most_similar_item = nil

        @all_items = TrustItem.all + Item.all

        @all_items.all.each do |ti|
          # Calculate Jaccard similarity
          jaccard_similarity = jaccard_similarity(title, ti.title)

          if jaccard_similarity > max_similarity
            max_similarity = jaccard_similarity
            most_similar_item = ti
          end
        end

        # **************************************************************
        # *********************** Check  Copy **************************
        # **************************************************************

        if max_similarity == 1
          source = item[:url].match(/^(https?:\/\/)?(?:www\.)?([a-zA-Z0-9.-]+)\//)&.[](2)
          matching_source = Source.all.find { |m| source.include?(m.name) }
          source = matching_source.name if matching_source.present?




          new_item = Item.new(title: item[:title], text: item[:body], author: item[:author],
                              url: item[:url], classification: 'Copy', pub_date: item[:publication_date],
                              user_id: User.first.id,content: item[:content], image_url: item[:image_url], source: source)



          if new_item.save
            puts "Saved new copy item"
            flash[:warning] = "Copy item was found"
          end

          earlier = most_similar_item.pub_date - item[:pub_date] if most_similar_item.present? && item[:pub_date]
          if earlier < 0
            FastNews.create(item_id: most_similar_item.id)
          else
            FastNews.create(item_id: Item.last.id)
          end
          redirect_to items_path
        end

        # **************************************************************
        # ******************** Check for Fake **************************
        # **************************************************************

        #***** fake logic


      end
    else

      puts 'Unable to fetch content from the URL.'
    end
  end

  private

  def fetch_with_nokogiri(url)
    Nokogiri::HTML(open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE, 'User-Agent' => 'Nooby'))
  rescue StandardError => e
    puts "Nokogiri failed: #{e.message}"
    nil
  end

  def fetch_with_mechanize(url)
    agent = Mechanize.new
    page = agent.get(url)
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    Nokogiri::HTML(page.body)
  rescue StandardError => e
    puts "Mechanize failed: #{e.message}"
    nil
  end

  def find_element(document, selectors)
    selectors.each do |selector|
      element = document.css(selector).first
      return element.text if element
    end
    ''
  end

  def find_attribute(document, selectors, attribute)
    selectors.each do |selector|
      element = document.css(selector).first
      return element[attribute] if element
    end
    ''
  end

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
