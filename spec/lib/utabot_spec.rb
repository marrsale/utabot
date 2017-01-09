require 'rspec'
require 'pry'

require 'spec_helper'

require './lib/utabot'

RSpec.describe Utabot do
  let(:soundcloud_client) { double 'SoundcloudClient' }

  subject { described_class.new soundcloud_client }

  it { is_expected.to respond_to :soundcloud }

  describe '#get_tracks' do
    describe 'pagination'
  end

  describe '#track_arguments' do
    describe 'with a genre' do
      it 'adds a key for genre when one is provided' do
        track_arg_hash = subject.track_arguments genre: 'genre'

        # we filter on 'q' instead, as the genre parameter does not work
        expect(subject.track_arguments genre: 'genre').to have_key :q
        expect(track_arg_hash[:q]).to eq 'genre'
      end

      it 'does not add a key for genre when not provided' do
        expect(subject.track_arguments).not_to have_key :genre
      end
    end

    describe 'with a limit' do
      let(:max_request_size) { Utabot::MAX_REQUEST_PAGE_SIZE }

      it 'adds a key for a limit when one is provided' do
        track_arg_hash = subject.track_arguments limit: 100

        expect(track_arg_hash).to have_key :limit
        expect(track_arg_hash[:limit]).to eq 100
      end

      it 'will not exceed a maximum page limit' do
        too_many_records = max_request_size + 1000
        track_arg_hash = subject.track_arguments limit: too_many_records

        expect(track_arg_hash[:limit] < too_many_records).to be true
        expect(track_arg_hash[:limit]).to eq max_request_size
      end

      it 'does not add a key for a limit when not provided' do
        expect(subject.track_arguments).not_to have_key :limit
      end
    end

    describe 'with a date range' do
      let(:past_week) { (Date.today - 7)..Date.today }
      let(:track_arg_hash_with_dates) { subject.track_arguments created_at: past_week }

      it 'adds a key for a date range when one is provided' do
        expect(track_arg_hash_with_dates).to have_key :created_at
      end

      it 'does not add a key for a date range when not provided' do
        expect(subject.track_arguments).not_to have_key :created_at
      end
    end
  end

  describe '#created_at_range' do
    let(:date_format) { %r{^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$} }

    describe 'provided a range object' do
      let(:today) { Date.today }
      let(:a_week_ago) { Date.today - 7 }
      let(:past_week) { a_week_ago..today }
      let(:created_at_query) { subject.created_at_range past_week }

      it 'forms an object with "from" and "to" values' do
        expect(created_at_query).to have_key :from
        expect(created_at_query).to have_key :to
      end

      it 'formats "from" and "to" values appropriately' do
        expect(created_at_query[:from]).to match date_format
        expect(created_at_query[:to]).to match date_format

        expect(created_at_query[:from]).to eq a_week_ago.strftime "%Y-%m-%d 00:00:00"
        expect(created_at_query[:to]).to eq today.strftime "%Y-%m-%d 00:00:00"
      end
    end
  end

  describe 'getting tracks from soundcloud' do
    it { is_expected.to respond_to :tracks_for_genre }

    it 'for a specified genre' do
      expect(subject).to receive(:get_tracks).with hash_including genre: 'disco'

      subject.tracks_for_genre 'disco'
    end

    it 'in a specified quantity' do
      expect(subject).to receive(:get_tracks).with hash_including limit: 100

      subject.tracks_for_genre 'disco', 100
    end

    describe 'for a specified interval' do
      let(:past_week) { (Date.today - 7)..Date.today }

      it 'when provided' do
        expect(subject).to receive(:get_tracks).with hash_including created_at: past_week

        subject.tracks_for_genre 'disco', for_dates: past_week
      end

      it 'unless none is given' do
        expect(soundcloud_client).not_to receive :get
      end
    end
  end

  describe 'picks the "best" song' do
    it 'from a given list of tracks'
    it 'based on custom criteria'
  end

  it 'adds a song to a playlist'
  it 'creates a playlist if there is not already a relevant one'

  it 'tweets a song'
  it 'reshares a song'
end
