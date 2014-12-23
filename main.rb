# Program constants
MAX_RECORDS  = 1000 # will only retrieve this many tracks
ONE_WEEK_AGO = (Date.today - 7).to_time
GENRES       = [{name: 'ambient', playlist_name: 'Ambient'},
                {name: 'deep house', playlist_name: 'Deep House'},
                {name: 'techno', playlist_name: 'Techno'}]

# The client object used for all wrapped HTTPfunctions
def client
  @client ||= SoundCloud.new(username: ENV['uname'],
                              password: ENV['pw'],
                              client_id: ENV['SOUNDCLOUD_CLIENT_ID'],
                              client_secret: ENV['SOUNDCLOUD_CLIENT_SECRET'])
end

# Dumb helper for comparing 'quality' of two tracks
def score(track1, track2)
  def kernel(track)
    score = 0
    score += track.comment_count unless track.comment_count.nil?
    score += track.playback_count || 0
    score += track.favoritings_count || 0
    score -= score * (300000/track.duration)
  end
  if kernel(track1) >= kernel(track2)
    return track1
  else
    return track2
  end
end

# Helper for getting a playlist by name or creating it if it doesn't exist
def get_playlist(client, name, pl_exists=false, retries=0)
  # Linear search helper, since bsearch and collect aren't working on small sets(?)
  def playlist_by_name(name)
    @playlists.each do |pl|
      return pl if name == pl.title
    end
  end

  @playlists = client.get('/me/playlists')
  # we have playlists, and the one we want to upload to is among them
  if @playlists && (playlist = playlist_by_name(name))
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
        # give up
        return nil
      end
    else
      # playlist doesn't exist, create it
      puts "Playlist #{name} doesn't exist already.  Creating it..."
      # client.post('/playlists', playlist: { title: name, sharing: 'public' })
      get_playlist(client, name, true)
    end
  end
end

puts 'For date '+ (ONE_WEEK_AGO.to_s)
GENRES.each do |genre|
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
  if (playlist = get_playlist(client, genre[:playlist_name])) && !(genre[:best_track].nil?)
    tracks = playlist.tracks.map { |t| t.id }
    tracks << genre[:best_track].id unless tracks.include?(genre[:best_track].id)
    # client.put(playlist.uri, playlist: {tracks: tracks.map { |t| { id: t } }})
    puts "\nAdded #{genre[:best_track].title} to #{genre[:playlist_name]}"
  end
end
