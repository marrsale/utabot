require 'date'

class TracksCollection < Struct.new :soundcloud, :tracks
  MAX_REQUEST_PAGE_SIZE = 200

  def for_genre genre, limit=nil, for_dates: nil
    self.tracks = get_tracks genre: genre, limit: limit, created_at: for_dates
    return self
  end

  private

  attr_accessor :last_response

  def get_tracks **args
    [].tap do |retrieved|
      self.last_response = nil

      while retrieved.size < (args[:limit] or 1)
        if last_response and last_response.next_href != ''
          self.last_response = soundcloud.get last_response.next_href
        else
          self.last_response = soundcloud.get '/tracks', track_arguments(args)
        end
        retrieved.push *last_response.collection
      end
    end
  end

  def track_arguments **args
    {}.tap do |options|
      options[:genres] = args[:genre] if not args[:genre].nil?
      options[:created_at] = 'last_week' if not args[:limit].nil?
      options[:limit] = [args[:limit], MAX_REQUEST_PAGE_SIZE].min if not args[:limit].nil?

      if (args[:limit] or 1) > MAX_REQUEST_PAGE_SIZE # we must paginate
        options[:linked_partitioning] = 1
      end
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

class Utabot < Struct.new :soundcloud, :twitter
  def hottest_for_genre genre, limit=100
    TracksCollection.new(soundcloud).for_genre(genre, limit).tracks.max_by &method(:score)
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
