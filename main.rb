require 'soundcloud'
require 'twitter'
require 'pry'

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

Genres = ['ambient', 'disco', 'deep house']

uta = Utabot.new client

best_7 = uta.hottest_x_for_genre 7, 'ambient', 20000
best_7.map(&:permalink_url).each &method(:puts)

# updated = []
# Genres.each do |genre|
#   best_song = uta.hottest_for_genre genre, 20000
#   puts "#{genre}: " + best_song.permalink_url
#   updated << (uta.playlist(genre).add best_song)
# end

# uta.tweet best_song
# uta.reshare best_song
