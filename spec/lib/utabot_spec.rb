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
        allow(subject).to receive(:score) {|x| x} # &:itself ???
      end

      it 'scored most highly by some criteria' do
        allow_any_instance_of(TracksCollection).to receive(:for_genre) {|c| c}
        allow_any_instance_of(TracksCollection).to receive(:tracks).and_return mock_tracks_collection

        expect(subject.hottest_for_genre 'disco').to eq mock_tracks_collection.max
      end
    end
  end

  describe '#hottest_n_for_genre' do
    it { is_expected.to respond_to :hottest_n_for_genre }

    describe 'returns tracks' do
      let(:mock_tracks_collection) { (1..10).to_a }

      before do
        allow(subject).to receive(:score) {|x| x}
        allow_any_instance_of(TracksCollection).to receive(:for_genre) {|c| c}
        allow_any_instance_of(TracksCollection).to receive(:tracks).and_return mock_tracks_collection
      end

      it 'in specified count' do
        expect(subject.hottest_n_for_genre(3, 'disco').count).to be 3
      end

      it 'scored most highly by some criteria in order of score' do
        expect(subject.hottest_n_for_genre 3, 'disco').to eq [10, 9, 8]
      end
    end
  end

  let(:song_title) { 'An Artist - A Song' }
  let(:song_url) { 'a_url_here' }
  let(:song_id) { 1 }
  let(:song) { double 'Track', title: song_title, permalink_url: song_url, id: song_id }

  describe '#tweet' do
    let(:twitter) { double 'Twitter' }

    it { is_expected.to respond_to :tweet }
    it { is_expected.to respond_to :twitter }

    before do
      subject.twitter = twitter
    end

    it 'takes a song and constructs a twitter message' do
      expected_message = "#{song_title} #{song_url}"

      expect(twitter).to receive(:update).with expected_message
      subject.tweet song
    end
  end

  describe '#reshare' do
    it { is_expected.to respond_to :reshare }

    it 'makes a put to soundcloud to share a song on your wall' do
      expect(soundcloud_client).to receive(:put).with "https://api.soundcloud.com/e1/me/track_reposts/#{song_id}"

      subject.reshare song
    end
  end

  describe '#playlist' do
    let(:playlist_name) { 'disco' }
    it { is_expected.to respond_to :playlist }

    it 'invokes Playlist.find' do
      expect(Playlist).to receive(:find).with playlist_name, soundcloud_client

      subject.playlist playlist_name
    end
  end
end
