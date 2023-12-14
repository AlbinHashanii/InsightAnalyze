# config/initializers/scheduler.rb
require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new


scheduler.every'1h' do
  ScrapeFromSourcesWorker.perform_async
end





