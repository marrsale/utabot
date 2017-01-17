require 'date'

require_relative 'core_ext'

require_relative 'tracks_collection'
require_relative 'playlist'

class Utabot < Struct.new :soundcloud, :twitter
  def hottest_for_genre genre, limit=100
    hottest_n_for_genre(1, genre, limit).first
  end

  def hottest_n_for_genre x, genre, limit=100
    TracksCollection.new(soundcloud).for_genre(genre, limit).tracks.uniq(&:id).sort_by(&method(:score)).last(x).reverse
  end

  def playlist name
    Playlist.find name, soundcloud
  end

  def tweet track
    twitter.update "#{track.title} #{track.permalink_url}"
  end

  def reshare track
    soundcloud.put "https://api.soundcloud.com/e1/me/track_reposts/#{track.id}"
  end

  def reshare_best_unique *tracks
    last_response = nil
    sorted_tracks = tracks.flatten.sort_by &method(:score)

    while not last_response&.status =~ /201/
      next_best_track = sorted_tracks.pop

      last_response = reshare next_best_track
    end
  end

  def score track
    (track.likes_count or 0) + (2*(track.reposts_count or 0))
  end
end
