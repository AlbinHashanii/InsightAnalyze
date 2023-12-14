class AllItemsController < ApplicationController
  include ItemsHelper
  def item_index
    @items = Item.all
    @trust_items = TrustItem.all

    @all_items = (@items + @trust_items).sort_by(&:created_at).reverse
    @paginated_items = WillPaginate::Collection.create(params[:page] || 1, 20, @all_items.length) do |pager|
      pager.replace @all_items[pager.offset, pager.per_page].to_a
    end

  end
  def search
    @search_value = params[:search_value]
    if @search_value.present?
      # Search for the @search_value in title or body for TrustItems and Items
      @search_items = (TrustItem.where("title LIKE :search_value COLLATE NOCASE OR text LIKE :search_value COLLATE NOCASE OR classification LIKE :search_value COLLATE NOCASE OR source LIKE :search_value COLLATE NOCASE", search_value: "%#{@search_value}%") |
        Item.where("title LIKE :search_value COLLATE NOCASE OR text LIKE :search_value COLLATE NOCASE OR classification LIKE :search_value COLLATE NOCASE OR source LIKE :search_value COLLATE NOCASE", search_value: "%#{@search_value}%"))
                        .sort_by(&:created_at).reverse
    end


    if @items.blank?
      @trust_items = TrustItem.paginate(page: params[:page], per_page: 20)
    end

    render 'item_index'
  end




  def show
    session[:previous_url] = request.referer
    @item = TrustItem.find_by(id: params[:id]) || Item.find_by(id: params[:id])

    if @item.nil?
      flash[:error] = "Item not found"
      redirect_to root_path
    end

    if @item.classification == 'Clickbait'
      @similar_words_array = []
      ClickbaitPattern.all.each do |cb|
        @similar_words_array << similar_words(@item.title, cb.pattern)
      end
    end

    @similar_words_array.flatten!.uniq! if @similar_words_array.present?

    if @item.classification == 'true'
      @klasifikimi = 'Lajm i vertete'
    elsif @item.classification == 'fake'
      @klasifikimi = 'Lajm i dyshimte'
    elsif @item.classification == 'Clickbait'
      @klasifikimi = 'Clickbait'
    elsif @item.classification == 'fact checking'
      @klasifikimi = 'Lajm i verfikuar me meteoden fact checking'
    end

    if @item.classification == 'Clickbait' && @similar_words_array.count < 3
      TrustItem.find(params[:id]).destroy
      redirect_to session.delete(:previous_url) || items_path
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

end
