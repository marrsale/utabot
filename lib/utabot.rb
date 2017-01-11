require 'date'

class TracksCollection < Struct.new :soundcloud, :tracks
  MAX_REQUEST_PAGE_SIZE = 200

  def for_genre genre, limit=nil, for_dates: nil
    self.tracks = get_tracks genre: genre, limit: limit, created_at: for_dates

    self
  end

  private

  def get_tracks **args
    # TODO: pagination
    soundcloud.get '/tracks', track_arguments(args)
  end

  def track_arguments **args
    {}.tap do |options|
      options[:genres] = args[:genre] if not args[:genre].nil?
      options[:created_at] = 'last_week' if not args[:limit].nil?
      options[:limit] = [args[:limit], MAX_REQUEST_PAGE_SIZE].min if not args[:limit].nil?
    end
  end

  def created_at_range interval
    from, to = [interval.first, interval.last].minmax

    {}.tap do |options|
      options[:from] = from.strftime "%Y-%m-%d 00:00:00"
      options[:to] = to.strftime "%Y-%m-%d 00:00:00"
    end
  end
end

class Utabot < Struct.new :soundcloud
  def hottest_for_genre genre
    TracksCollection.new(soundcloud).for_genre.max_by &method(:score)
  end

  def score track
    score = 0.to_f
    score += (track.playback_count.to_f or 0.to_f)
    index = ((track.likes_count.to_f or 0.to_f)/(track.playback_count.to_f or 1.to_f))
    score *= index
  end
end
