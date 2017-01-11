require 'rspec'
require 'pry'
require 'soundcloud'

require './lib/utabot'

def client
  @client ||= SoundCloud.new username: ENV['uname'],
                              password: ENV['pw'],
                              client_id: ENV['SOUNDCLOUD_CLIENT_ID'],
                              client_secret: ENV['SOUNDCLOUD_CLIENT_SECRET']
end

def twitter
  @twitter_client ||= Twitter::REST::Client.new do |c|
    c.consumer_key        = ENV['utabot_twitter_consumer_key']
    c.consumer_secret     = ENV['utabot_twitter_consumer_secret']
    c.access_token        = ENV['utabot_twitter_access_token']
    c.access_token_secret = ENV['utabot_twitter_access_token_secret']
  end
end

uta = Utabot.new client
best_disco_song = uta.hottest_for_genre 'ambient', 10000
puts best_disco_song.permalink_url
# res = uta.for_genre 'disco', 200, for_dates: (Date.today - 7)..Date.today
# best = res.reject{|t| t.playback_count == 0 or t.duration > 600000 }.sort_by(&uta.method(:score)).last
#
#
# puts best.permalink_url
# best_disco_song = uta.hottest_for_genre 'disco'
# uta.tweet best_disco_song
# uta.reshare best_disco_song
# uta.playlist('disco').add best_disco_song

# Reshare on SoundCloud
# reshare(best_in_order.first)
# Tweet it on twitter
# twitter.update("#{best_in_order.first.title} #{best_in_order.first.permalink_url}")
