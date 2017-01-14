require 'spec_helper'

require './lib/playlist'

RSpec.describe Playlist do
  let(:soundcloud_client) { double 'SoundcloudClient' }
  let(:name) { 'disco' }
  let(:id) { 1 }
  let(:token) { 'a_secret_token' }
  let(:track) { double 'Track', id: 1 }
  let(:tracks) { [track] }
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
      allow(subject).to receive(:tracks).and_return []

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

    describe 'returns', pending: 'API document discovery' do
      it 'new version of itself on success'
      it 'current version of itself when unsuccessful', pending: 'what to return?'
    end
  end

  describe '#add_first_unique' do
    it { is_expected.to respond_to :add_first_unique }
    let(:new_track) { double 'Track', id: 2 }

    it 'with at least one track not already present adds the first track not already present' do
      expect(subject).to receive(:add).with new_track

      subject.add_first_unique [track, new_track]
    end

    it 'with no tracks not already present does not add anything' do
      allow(subject).to receive(:tracks).and_return [track, new_track]
      expect(subject).not_to receive(:add).with new_track

      subject.add_first_unique [track, new_track]
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
