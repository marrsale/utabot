require 'date'

require_relative 'core_ext'

require_relative 'tracks_collection'
require_relative 'playlist'

class Utabot < Struct.new :soundcloud, :twitter
  def hottest_for_genre genre, limit=100
    TracksCollection.new(soundcloud).for_genre(genre, limit).tracks.max_by &method(:score)
  end

  def hottest_x_for_genre x, genre, limit=100
    TracksCollection.new(soundcloud).for_genre(genre, limit).tracks.sort_by(&method(:score)).last(x).reverse
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

  def score track
    begin
      score = 0.to_f
      score += (track.playback_count.to_f or 0.to_f)
      index = ((track.likes_count.to_f or 0.to_f)/(track.playback_count.to_f or 1.to_f))
      score *= index
    rescue
      0.0
    end

    score.nan? ? 0 : score
  end
end
