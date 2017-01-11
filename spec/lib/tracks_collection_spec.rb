require 'spec_helper'

require './lib/tracks_collection'

def soundcloud_response collection, next_href=''
  double 'SoundcloudResponse', collection: collection, next_href: next_href
end

RSpec.describe TracksCollection do
  let(:soundcloud_client) { double 'SoundcloudClient' }
  let(:max_request_size) { described_class::MAX_REQUEST_PAGE_SIZE }

  subject { described_class.new soundcloud_client }

  it { is_expected.to respond_to :soundcloud }

  describe '#get_tracks' do
    let(:track) { double 'Track' }
    let(:fifty_tracks) { Array.new 50, track }
    let(:fifty_records) { soundcloud_response fifty_tracks }

    before do
      allow(soundcloud_client).to receive(:get).and_return fifty_records
    end

    it 'returns a list of tracks' do
      expect(subject.send :get_tracks).to eq fifty_records.collection
    end

    it 'always sets a last_response, even if only need one page' do
      expect{subject.send :get_tracks}.to change {subject.send :last_response}
    end

    describe 'pagination' do
      let(:last_page_response) { soundcloud_response fifty_tracks, '' }

      it 'does not paginate for small requests' do
        expect(soundcloud_client).to receive(:get).exactly(1).times

        subject.send :get_tracks, limit: 50
      end

      it 'uses linked partitioning when necessary' do
        next_href = 'next_href'
        two_hundred_records = soundcloud_response Array.new(200, track), next_href
        allow(soundcloud_client).to receive(:get).and_return two_hundred_records

        expect(soundcloud_client).to receive(:get).with(next_href)

        subject.send :get_tracks, limit: (max_request_size + 1)
      end

      describe 'loop terminates' do
        it 'when specified limit is reached' do
          expect(soundcloud_client).to receive(:get).exactly(2).times.and_return fifty_records

          subject.send :get_tracks, limit: 100
        end

        it 'before specified limit is reached but no more records exist' do
          allow(subject).to receive(:last_response).and_return last_page_response

          subject.send :get_tracks, limit: (max_request_size + 1)
        end
      end
    end
  end

  describe '#track_arguments' do
    describe 'for pagination' do
      it 'adds a linked partitioning argument when we request more than one page' do
        track_arg_hash = subject.send :track_arguments, limit: (max_request_size + 1)

        expect(track_arg_hash).to have_key :linked_partitioning
        expect(track_arg_hash[:linked_partitioning]).to be 1
      end

      it 'does not add pagination argument for small requests' do
        track_arg_hash = subject.send :track_arguments, limit: 1

        expect(track_arg_hash).not_to have_key :linked_partitioning
      end
    end

    describe 'with a genre' do
      it 'adds a key for genre when one is provided' do
        track_arg_hash = subject.send :track_arguments, genre: 'genre'

        expect(track_arg_hash).to have_key :genres
        expect(track_arg_hash[:genres]).to eq 'genre'
      end

      it 'does not add a key for genre when not provided' do
        expect(subject.send :track_arguments).not_to have_key :genres
      end
    end

    describe 'with a limit' do
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
