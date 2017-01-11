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

# Helper for resharing to SC stream if the song hasn't been reshared already
# NOTE this isn't an officially supported action, and so is a little hacky
# http://stackoverflow.com/questions/19266083/reposting-a-track-via-the-soundcloud-api
# http://stackoverflow.com/questions/14914059/soundcloud-api-extracting-tracks-reposted-by-a-user
def reshare track
  client.put "https://api.soundcloud.com/e1/me/track_reposts/#{track.id}"
end

uta = Utabot.new client
tracks = TracksCollection.new(client).for_genre 'disco'

binding.pry

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
