class ScrapeFromSourcesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :scrape_from_sources
  def perform
    RssParserController.new.index
  end
end


















