require 'rails_helper'

RSpec.describe WelcomeMailer, type: :mailer do
  describe '#welcome' do
    let(:user) { build(:user, first_name: 'Mauricio', email: 'mauricio@example.com') }
    let(:mail) { described_class.welcome(user) }

    it 'sends to the user email' do
      expect(mail.to).to eq(['mauricio@example.com'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq('Welcome to Train Like Dubi')
    end

    it 'sends from the platform address' do
      expect(mail.from.first).to include('trainlikedubi.com')
    end

    it 'includes the user first name in the body' do
      expect(mail.body.encoded).to include('Mauricio')
    end

    it 'includes a link to the videos page' do
      expect(mail.body.encoded).to include('Start Watching')
    end

    it 'mentions Mauricio Dubón' do
      expect(mail.body.encoded).to include('Dubón')
    end
  end
end
