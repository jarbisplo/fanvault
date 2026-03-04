require 'rails_helper'

RSpec.describe Video, type: :model do
  let(:admin) { create(:user, :admin) }

  describe 'validations' do
    it 'requires a title' do
      video = build(:video, creator: admin, title: '')
      video.save(validate: false) # skip to get an id
      video.title = ''
      expect(video).not_to be_valid
      expect(video.errors[:title]).to include("can't be blank")
    end

    it 'requires video_file on create' do
      video = Video.new(
        creator: admin, title: 'Test', status: :draft, visibility: :subscribers_only
      )
      expect(video).not_to be_valid
      expect(video.errors[:video_file]).to include("can't be blank")
    end

    it 'does NOT require video_file on update' do
      video = create(:video, creator: admin)
      video.title = 'Updated title'
      expect(video).to be_valid
    end
  end

  describe '#free?' do
    it 'is false by default' do
      video = build(:video, creator: admin)
      expect(video.free?).to be false
    end

    it 'is true when marked free' do
      video = build(:video, creator: admin, free: true)
      expect(video.free?).to be true
    end
  end

  describe '#accessible_by?' do
    let(:subscriber) { create(:user) }
    let(:non_sub)    { create(:user) }
    let(:video)      { create(:video, creator: admin, free: false) }

    before do
      create(:subscription, creator: admin, subscriber: subscriber, status: :active)
    end

    it 'is accessible by admin' do
      expect(video.accessible_by?(admin)).to be true
    end

    it 'is accessible by active subscriber' do
      expect(video.accessible_by?(subscriber)).to be true
    end

    it 'is NOT accessible by non-subscriber' do
      expect(video.accessible_by?(non_sub)).to be false
    end

    it 'is NOT accessible by nil (logged-out)' do
      expect(video.accessible_by?(nil)).to be false
    end

    context 'when video is free' do
      let(:video) { create(:video, creator: admin, free: true) }

      it 'is accessible by non-subscriber' do
        expect(video.accessible_by?(non_sub)).to be true
      end

      it 'is accessible by nil (logged-out)' do
        expect(video.accessible_by?(nil)).to be true
      end
    end
  end
end
