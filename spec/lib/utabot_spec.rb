require 'spec_helper'

require './lib/utabot'

RSpec.describe Playlist do
  let(:soundcloud_client) { double 'SoundcloudClient' }
  let(:name) { 'disco' }
  let(:id) { 1 }
  let(:token) { 'a_secret_token' }
  let(:tracks) { [] }
  let(:track) { double 'Track', id: 1 }
  let(:soundcloud_playlist_data) do
    double 'SoundcloudPlaylist',
      id: id,
      secret_token: token,
      title: name,
      tracks: tracks,
      uri: 'a uri'
  end

  subject { described_class.new soundcloud_playlist_data, soundcloud_client }

  it { is_expected.to respond_to :soundcloud }

  describe 'delegates' do
    it 'calls appropriate methods on data' do
      expect(subject.name).to eq name
      expect(subject.secret_token).to eq token
      expect(subject.id).to eq id
      expect(subject.tracks).to be tracks
    end
  end

  describe '#add_track_args' do
    it 'creates a Rails-style nested RESTful resource structure' do
      expected_result = {
        playlist: {
          tracks: [{id: track.id}]
        }
      }

      expect(subject.send :add_track_args, track).to eq expected_result
    end
  end

  describe '#add' do
    it { is_expected.to respond_to :add }

    it 'makes a PUT request to soundcloud' do
      expect(soundcloud_client).to receive(:put)

      subject.add track
    end

    describe 'returns' do
      it 'new version of itself on success'
      it 'false when unsuccessful'
    end
  end

  describe '.find' do
    let(:playlist_name) { 'disco' }
    let(:playlists_response) do
      [playlist_name, 'folk', 'yodeling'].map do |name|
        double 'SoundcloudPlaylist', title: name
      end
    end

    subject { described_class }

    before do
      allow(soundcloud_client).to receive(:get).and_return playlists_response
    end

    describe 'returns' do
      it 'the playlist if one exists by a given name' do
        expect(subject.find(playlist_name, soundcloud_client)).to be_a Playlist
        expect(subject.find(playlist_name, soundcloud_client).name).to eq playlist_name
      end

      it 'nil if one does not exist by a given name' do
        expect(subject.find('fakename', soundcloud_client)).not_to be_a Playlist
        expect(subject.find('fakename', soundcloud_client)).to be nil
      end
    end
  end
end

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
