require 'spec_helper'

require './lib/utabot'

RSpec.describe Utabot do
  let(:soundcloud_client) { double 'SoundcloudClient' }

  subject { described_class.new soundcloud_client }

  describe '#hottest_for_genre' do
    it { is_expected.to respond_to :hottest_for_genre }

    describe 'returns a track' do
      let(:mock_tracks_collection) { (1..10).to_a }

      before do
        allow(subject).to receive(:score).and_do &:tap
      end

      it 'scored most highly by some criteria', skip: 'implement #for_genre' do
        allow_any_instance_of(TracksCollection).to receive(:for_genre).and_return mock_tracks_collection

        expect(subject.hottest_for_genre 'disco').to eq mock_tracks_collection.max
      end
    end
  end

  describe '#tweet'
  describe '#reshare'
  describe '#playlist' do
    describe '#playlist(foo).add'
  end
end

RSpec.describe TracksCollection do
  let(:soundcloud_client) { double 'SoundcloudClient' }

  subject { described_class.new soundcloud_client }

  it { is_expected.to respond_to :soundcloud }

  describe '#get_tracks' do
    describe 'pagination: continuously retrieves records while appropriate' do
      it 'until limit is reached'
      it 'until there are no more records'
    end
  end

  describe '#track_arguments' do
    describe 'with a genre' do
      it 'adds a key for genre when one is provided' do
        track_arg_hash = subject.send :track_arguments, genre: 'genre'

        # we filter on 'q' instead, as the genre parameter does not work
        expect(subject.send :track_arguments, genre: 'genre').to have_key :genres
        expect(track_arg_hash[:genres]).to eq 'genre'
      end

      it 'does not add a key for genre when not provided' do
        expect(subject.send :track_arguments).not_to have_key :genres
      end
    end

    describe 'with a limit' do
      let(:max_request_size) { described_class::MAX_REQUEST_PAGE_SIZE }

      it 'adds a key for a limit when one is provided' do
        track_arg_hash = subject.send :track_arguments, limit: 100

        expect(track_arg_hash).to have_key :limit
        expect(track_arg_hash[:limit]).to eq 100
      end

      it 'will not exceed a maximum page limit' do
        too_many_records = max_request_size + 1000
        track_arg_hash = subject.send :track_arguments, limit: too_many_records

        expect(track_arg_hash[:limit] < too_many_records).to be true
        expect(track_arg_hash[:limit]).to eq max_request_size
      end

      it 'does not add a key for a limit when not provided' do
        expect(subject.send :track_arguments).not_to have_key :limit
      end
    end

    describe 'with a date range', skip: 'See TODOs in README' do
      let(:past_week) { (Date.today - 7)..Date.today }
      let(:track_arg_hash_with_dates) { subject.send :track_arguments, created_at: past_week }

      it 'adds a key for a date range when one is provided' do
        expect(track_arg_hash_with_dates).to have_key :created_at
      end

      it 'does not add a key for a date range when not provided', skip: 'See relevant TODO' do
        expect(subject.send :track_arguments).not_to have_key :created_at
      end
    end
  end

  describe '#created_at_range' do
    let(:date_format) { %r{^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$} }

    describe 'provided a range object' do
      let(:today) { Date.today }
      let(:a_week_ago) { Date.today - 7 }
      let(:past_week) { a_week_ago..today }
      let(:created_at_query) { subject.send :created_at_range, past_week }

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

  describe '#for_genre' do
    it { is_expected.to respond_to :for_genre }

    it 'retrieves and returns self populated with tracks' do
      allow(subject).to receive(:get_tracks).and_return double 'SoundcloudResponse'

      expect(subject.for_genre 'disco').to be subject
    end
  end
end
