require 'rails_helper'

RSpec.describe NewVideoMailer, type: :mailer do
  describe '#notify' do
    let(:creator) { create(:user, :admin) }
    let(:user)    { build(:user, first_name: 'Alex', email: 'alex@example.com') }
    let(:video) do
      create(:video,
        creator:     creator,
        title:       'Morning Mobility Routine',
        description: 'Start every day moving right.')
    end
    let(:mail) { described_class.notify(user, video) }

    it 'sends to the subscriber email' do
      expect(mail.to).to eq(['alex@example.com'])
    end

    it 'includes the video title in the subject' do
      expect(mail.subject).to include('Morning Mobility Routine')
    end

    it 'sends from the platform address' do
      expect(mail.from.first).to include('trainlikedubi.com')
    end

    it 'includes the user first name' do
      expect(mail.body.encoded).to include('Alex')
    end

    it 'includes the video title in the body' do
      expect(mail.body.encoded).to include('Morning Mobility Routine')
    end

    it 'includes the video description in the body' do
      expect(mail.body.encoded).to include('Start every day moving right')
    end

    it 'has a Watch Now call to action' do
      expect(mail.body.encoded).to include('Watch Now')
    end
  end
end
