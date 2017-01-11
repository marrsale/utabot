require 'date'

require_relative 'tracks_collection'

class BasicObject
  def self.delegate *methods, to:
    methods.each do |meth|
      define_method(meth.to_sym) do |*args, &block|
        send(to).send meth, *args, &block
      end
    end
  end
end

class Playlist < Struct.new :data, :soundcloud
  delegate :title, :id, :secret_token, :tracks, to: :data

  alias_method :name, :title

  def add track
    soundcloud.put data.uri, add_track_args(track)
  end

  private

  def add_track_args track
    tracks_array = tracks.map do |t|
      { id: t.id }
    end

    {
      playlist: {
        tracks: tracks_array + [{ id: track.id }]
      }
    }
  end

  class << self
    def find name, soundcloud
      playlist = soundcloud.get('/me/playlists').find {|pl| pl.title == name }
      playlist.nil? ? nil : self.new(playlist, soundcloud)
    end
  end
end

class Utabot < Struct.new :soundcloud, :twitter
  def hottest_for_genre genre, limit=100
    TracksCollection.new(soundcloud).for_genre(genre, limit).tracks.max_by &method(:score)
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
