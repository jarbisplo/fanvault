require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  describe '#reset_password_instructions' do
    let(:user)  { create(:user, first_name: 'Javier', email: 'javier@example.com') }
    let(:token) { 'fake_reset_token_abc123' }
    let(:mail)  { described_class.reset_password_instructions(user, token) }

    it 'sends to the user email' do
      expect(mail.to).to eq(['javier@example.com'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq('Reset password instructions')
    end

    it 'sends from the platform address' do
      expect(mail.from.first).to include('trainlikedubi.com')
    end

    it 'includes the user first name' do
      expect(mail.body.encoded).to include('Javier')
    end

    it 'includes a password reset link' do
      expect(mail.body.encoded).to include('Reset Password')
    end

    it 'includes the reset token in the link' do
      expect(mail.body.encoded).to include(token)
    end

    it 'mentions the expiry' do
      expect(mail.body.encoded).to include('expires')
    end
  end
end
