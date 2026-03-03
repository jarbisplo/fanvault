require 'rails_helper'

RSpec.describe SubscriptionMailer, type: :mailer do
  let(:creator)      { create(:user, :admin) }
  let(:subscriber)   { build(:user, first_name: 'Alex', email: 'alex@example.com') }
  let(:plan)         { build(:plan, creator: creator) }
  let(:subscription) do
    build(:subscription,
      creator:             creator,
      subscriber:          subscriber,
      plan:                plan,
      status:              :active,
      current_period_end:  Time.zone.parse('2026-04-03'))
  end

  describe '#confirmed' do
    let(:mail) { described_class.confirmed(subscriber, subscription) }

    it 'sends to the subscriber' do
      expect(mail.to).to eq(['alex@example.com'])
    end

    it 'has a subscription confirmed subject' do
      expect(mail.subject).to include("subscribed")
    end

    it 'sends from the platform address' do
      expect(mail.from.first).to include('trainlikedubi.com')
    end

    it 'greets the subscriber by name' do
      expect(mail.body.encoded).to include('Alex')
    end

    it 'shows the next billing date' do
      expect(mail.body.encoded).to include('April 3, 2026')
    end

    it 'has a Start Watching CTA' do
      expect(mail.body.encoded).to include('Start Watching')
    end
  end

  describe '#cancelled' do
    let(:mail) { described_class.cancelled(subscriber, subscription) }

    it 'sends to the subscriber' do
      expect(mail.to).to eq(['alex@example.com'])
    end

    it 'has a cancellation subject' do
      expect(mail.subject).to include('cancelled')
    end

    it 'greets the subscriber by name' do
      expect(mail.body.encoded).to include('Alex')
    end

    it 'mentions the access end date' do
      expect(mail.body.encoded).to include('April 3, 2026')
    end

    it 'offers a resubscribe link' do
      expect(mail.body.encoded).to include('Resubscribe')
    end
  end

  describe '#payment_failed' do
    let(:mail) { described_class.payment_failed(subscriber, subscription) }

    it 'sends to the subscriber' do
      expect(mail.to).to eq(['alex@example.com'])
    end

    it 'has an urgent subject' do
      expect(mail.subject).to include('payment failed')
    end

    it 'greets the subscriber by name' do
      expect(mail.body.encoded).to include('Alex')
    end

    it 'explains the payment issue' do
      expect(mail.body.encoded).to include("weren't able to process")
    end

    it 'has an Update Payment Method CTA' do
      expect(mail.body.encoded).to include('Update Payment Method')
    end

    it 'mentions the grace period' do
      expect(mail.body.encoded).to include('grace period')
    end
  end
end
