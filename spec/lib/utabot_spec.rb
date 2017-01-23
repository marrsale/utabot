require 'spec_helper'

require './lib/utabot'

RSpec.describe Utabot do
  let(:soundcloud_client) { double 'SoundcloudClient' }

  subject { described_class.new soundcloud_client }

  describe '#hottest_for_genre' do
    let(:track) { :a_track }

    before do
      allow(subject).to receive(:hottest_n_for_genre).and_return [track]
    end

    it { is_expected.to respond_to :hottest_for_genre }

    it 'returns a singular item' do
      expect(subject.hottest_for_genre 'disco').to be track
    end

    it 'invokes #hottest_n_for_genre with correct args' do
      expect(subject).to receive(:hottest_n_for_genre).with(1, 'disco', 1000)

      subject.hottest_for_genre 'disco', 1000
    end
  end

  describe '#hottest_n_for_genre' do
    it { is_expected.to respond_to :hottest_n_for_genre }

    describe 'returns tracks' do
      let(:mock_track_scores) { (1..10).to_a }
      let(:mock_tracks_collection) do
        mock_track_scores.map do |score|
          double 'Track', id: score, score: score
        end
      end

      before do
        allow(subject).to receive(:score) {|x| x.score}
        allow_any_instance_of(TracksCollection).to receive(:for_genre) {|c| c}
        allow_any_instance_of(TracksCollection).to receive(:tracks).and_return mock_tracks_collection
      end

      it 'in specified count' do
        expect(subject.hottest_n_for_genre(3, 'disco').count).to be 3
      end

      it 'scored most highly by some criteria in order of score' do
        expect(subject.hottest_n_for_genre 3, 'disco').to eq mock_tracks_collection.last(3).reverse
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

  describe '#reshare_best_unique' do
    let(:previously_reshared_track) { double 'Track', id: 1, score: 3 }
    let(:first_unreshared_track) { double 'Track', id: 2, score: 2 }
    let(:tracks) { [previously_reshared_track, first_unreshared_track, (double 'Track', id: 3, score: 1)] }

    let(:ok_response) { double 'Response', code: 200 }
    let(:created_response) { double 'Response', code: 201 }

    before do
      allow(subject).to receive(:score) do |track|
        track.score
      end
    end

    it 'reshares the first song not-already reshared' do
      allow(subject).to receive(:reshare).with(previously_reshared_track).and_return ok_response
      allow(subject).to receive(:reshare).with(first_unreshared_track).and_return created_response

      expect(subject).to receive(:reshare).exactly(2).times

      subject.reshare_best_unique tracks
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
