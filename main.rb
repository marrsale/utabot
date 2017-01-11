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

Genres = ['ambient', 'disco', 'deep house']

uta = Utabot.new client
updated = []

Genres.each do |genre|
  best_song = uta.hottest_for_genre genre, 20000
  puts "#{genre}: " + best_song.permalink_url
  updated << (uta.playlist(genre).add best_song)
end


# uta.tweet best_disco_song
# uta.reshare best_disco_song
