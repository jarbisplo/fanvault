# == Schema Information
# id, creator_id, subscriber_id, plan_id, status, kind (paid/invited),
# stripe_subscription_id, current_period_end, invited_by_id, created_at, updated_at

class Subscription < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :subscriber, class_name: 'User'
  belongs_to :plan, optional: true
  belongs_to :invitation, optional: true

  enum :status, { pending: 0, active: 1, cancelled: 2, expired: 3, past_due: 4 }
  enum :kind, { paid: 0, invited: 1 }

  validates :creator, :subscriber, presence: true
  validates :subscriber_id, uniqueness: { scope: :creator_id, message: 'is already subscribed to this creator' }
  validate :subscriber_is_not_creator

  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }

  def self.create_from_invitation!(invitation)
    create!(
      creator: invitation.creator,
      subscriber: invitation.subscriber,
      kind: :invited,
      status: :active,
      invitation: invitation
    )
  end

  def cancel!
    update!(status: :cancelled)
    # Cancel Stripe subscription if paid
    if paid? && stripe_subscription_id.present?
      Stripe::Subscription.update(stripe_subscription_id, cancel_at_period_end: true)
    end
  end

  private

  def subscriber_is_not_creator
    errors.add(:subscriber, "can't subscribe to yourself") if subscriber == creator
  end
end
