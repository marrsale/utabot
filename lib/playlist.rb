class Playlist < Struct.new :data, :soundcloud
  delegate :title, :id, :secret_token, :tracks, to: :data

  alias_method :name, :title

  def add track
    soundcloud.put data.uri, add_track_args(track)
  end

  def add_first_unique prospective_tracks
    new_tracks = prospective_tracks.reject do |t|
      track_ids.include? t.id
    end

    add new_tracks.first if new_tracks.any?
  end

  private

  def track_ids
    @track_ids ||= self.tracks.map &:id
  end

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
