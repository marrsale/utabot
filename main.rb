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

Genres = %w(ambient disco deep\ house)

AddToPlaylist = !ARGV.include?('noplaylist')
Reshare       = !ARGV.include?('noreshare')

uta = Utabot.new client

results = []

Genres.each do |genre|
  puts "#{genre}: "
  best_seven = uta.hottest_n_for_genre 7, genre, 20000
  results.push *best_seven

  best_seven.map(&:permalink_url).each &method(:puts)

  uta.playlist(genre).add_first_unique best_seven if AddToPlaylist
end

uta.reshare_best_unique results if Reshare

# best_song = results.sort_by(&uta.method(:score)).last
# uta.tweet best_song
