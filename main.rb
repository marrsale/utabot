# Program constants
MAX_RECORDS  = 1000 # will only retrieve this many tracks
RETRY_COUNT  = 20
ONE_WEEK_AGO = (Date.today - 7).to_time
GENRES       = [{name: 'ambient', playlist_name: 'Ambient'},
                {name: 'deep house', playlist_name: 'Deep House'},
                {name: 'disco', playlist_name: 'Disco'}]

# The client object used for all wrapped HTTPfunctions
def client
  @client ||= SoundCloud.new(username: ENV['uname'],
                              password: ENV['pw'],
                              client_id: ENV['SOUNDCLOUD_CLIENT_ID'],
                              client_secret: ENV['SOUNDCLOUD_CLIENT_SECRET'])
end

def twitter
  @twitter_client ||= Twitter::REST::Client.new do |c|
    c.consumer_key        = ENV['utabot_twitter_consumer_key']
    c.consumer_secret     = ENV['utabot_twitter_consumer_secret']
    c.access_token        = ENV['utabot_twitter_access_token']
    c.access_token_secret = ENV['utabot_twitter_access_token_secret']
  end
end

# Helpers for comparing 'quality' of two tracks
def parameterize(track)
  score = 0
  score += track.comment_count unless track.comment_count.nil?
  score += track.playback_count || 0
  score += track.favoritings_count || 0
  score -= score * (300000/track.duration)
end

def score(track1, track2)
  if parameterize(track1) >= parameterize(track2)
    return track1
  else
    return track2
  end
end

# Helper for getting a playlist by name or creating it if it doesn't exist
def get_playlist(client, name, pl_exists=false, retries=0, error=nil)
  raise 'Couldnt find or create playlist' if retries > RETRY_COUNT
  begin
    # Linear search helper, since bsearch and collect aren't working on small sets(?)
    def playlist_by_name(name)
      @playlists.each do |pl|
        if name == pl.title
          return pl
        end
      end
      return nil
    end

    @playlists = client.get('/me/playlists')
    # the playlist we want to upload to is among them
    if (playlist = playlist_by_name(name))
      "Found playlist #{name}"
      return playlist
    else
      if pl_exists
        puts "Waiting on soundcloud..."
        # we know we just created it and we're waiting on soundcloud
        sleep 2
        if retries <= 10
          get_playlist(client, name, pl_exists, (retries + 1))
        else
          return nil
        end
      else
        # playlist doesn't exist, create it
        puts "Playlist #{name} doesn't exist already.  Creating it..."
        ret = client.post('/playlists', playlist: { title: name, sharing: 'public' })
        sleep 20
        get_playlist(client, name, true)
      end
    end
  rescue StandardError => e
    sleep 1
    get_playlist(client, name, pl_exists, (retries + 1), e)
  end
end

# Helper for resharing if the song hasn't been reshared already
# NOTE: this seems hacky because it is
#   http://stackoverflow.com/questions/19266083/reposting-a-track-via-the-soundcloud-api
#   http://stackoverflow.com/questions/14914059/soundcloud-api-extracting-tracks-reposted-by-a-user
def reshare(track)
  client.put("https://api.soundcloud.com/e1/me/track_reposts/#{track.id}")
end

# The main program
puts 'For date '+ (ONE_WEEK_AGO.to_s)
GENRES.each do |genre|
  begin
    puts "For genre #{genre[:name]}:"
    best_track   = nil
    high_score   = 0
    retrieved_ct = 0
    finalists    = genre[:finalists] = []

    # pagination loop
    while retrieved_ct < MAX_RECORDS
      # Get tracks for genre, by hotness posted one week ago
      if (hottest = client.get('/tracks', q: genre[:name], order: 'hotness', created_at: 'last_week', limit: 200, offset: retrieved_ct))
        retrieved_ct += hottest.count
        print "\rRetrieved #{retrieved_ct} of #{MAX_RECORDS} records."

        hottest.each do |track|
          created_at = Time.parse(track.created_at)
          # Find all sounds that have ACTUALLY been posted on the day one week ago
          if (Time.parse(track.created_at) >= ONE_WEEK_AGO && Time.parse(track.created_at) < ((ONE_WEEK_AGO.to_date) + 1).to_time) && track.genre = genre[:name] && track.duration >= 180000
            finalists << track
            genre[:best_track] = track if (genre[:best_track].nil? || score(genre[:best_track], track) != genre[:best_track])
          end
        end
      end
    end

    # Upload the tracks
    if (playlist = get_playlist(client, genre[:playlist_name])) && !(genre[:best_track].nil?)
      tracks = playlist.tracks.map { |t| t.id }
      if !(tracks.include?(genre[:best_track].id))
        tracks << genre[:best_track].id
        client.put(playlist.uri, playlist: {tracks: tracks.map { |t| { id: t } }})
        puts "\nAdded #{genre[:best_track].title} to #{genre[:playlist_name]}"
      end
    end

  rescue StandardError => e
    puts "\nFailed once for genre #{genre[:name]} (#{e.message}), looping next genre.\n\n"
  end
end

# Now all the hard work is done, pick just the best one to reshare
best_in_order = GENRES.map { |g| g[:best_track] }.sort { |a,b| parameterize(b) <=> parameterize(a) } # the best tracks, from greatest to least score
# Reshare on SoundCloud
reshare(best_in_order.first)
# Tweet it on twitter
twitter.update("#{best_in_order.first.title} #{best_in_order.first.permalink_url}")
