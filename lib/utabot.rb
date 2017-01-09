require 'date'

class Utabot < Struct.new :soundcloud
  MAX_REQUEST_PAGE_SIZE = 200 # TODO: better organize configuration constants

  def hottest_for_genre genre

  end

  def tracks_for_genre genre, limit=nil, for_dates: nil
    get_tracks genre: genre, limit: limit, created_at: for_dates
  end

  def score track
    score = 0.to_f
    score += (track.playback_count.to_f or 0.to_f)
    index = ((track.likes_count.to_f or 0.to_f)/(track.playback_count.to_f or 0.to_f))
    score *= index
  end

  private

  def get_tracks **args
    # TODO: pagination
    soundcloud.get '/tracks', track_arguments(args)
  end

  def track_arguments **args
    {}.tap do |options|
      options[:genres] = args[:genre] if not args[:genre].nil?
      options[:limit] = [args[:limit], MAX_REQUEST_PAGE_SIZE].min if not args[:limit].nil?
      options[:created_at] = created_at_range(args[:created_at]) if not args[:created_at].nil?
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
