class SourcesController < ApplicationController
  before_action :set_source
  def index
    @source = Source.all
    @fact_checking = FactCheckingSource.all

    @sources = (@source + @fact_checking).sort_by(&:created_at).reverse
  end

  def index_2
    @source = Source.new
  end

  def create
    name = params[:source][:name]
    url = params[:source][:url]
    trust_type_check = params[:source][:trust_type]

    if url.present? && name.present?
      @source.name = name
      @source.url = url
      if trust_type_check == "1"
        FactCheckingSource.create(name: name, url: url, trust_type: 'fact checking')
        redirect_to sources_path
      elsif trust_type_check == "0"
        @source.trust_type = "true"
        @source.save
        redirect_to sources_path
      end
    end



  end

  def set_source
    @source = Source.new
  end
end