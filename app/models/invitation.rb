# == Schema Information
# id, creator_id, subscriber_id, email, token, status (pending/accepted/expired),
# expires_at, accepted_at, created_at, updated_at

class Invitation < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :subscriber, class_name: 'User', optional: true
  has_one :subscription

  enum status: { pending: 0, accepted: 1, expired: 2, revoked: 3 }

  before_create :generate_token
  before_create :set_expiry

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :creator, presence: true
  validates :email, uniqueness: { scope: :creator_id, conditions: -> { where(status: :pending) },
                                  message: 'already has a pending invitation from this creator' }

  scope :pending_valid, -> { pending.where('expires_at > ?', Time.current) }

  def accept!(user)
    return false unless pending?
    return false if expired?

    transaction do
      update!(status: :accepted, subscriber: user, accepted_at: Time.current)
      Subscription.create_from_invitation!(self)
    end
    true
  end

  def expired?
    expires_at < Time.current
  end

  def revoke!
    update!(status: :revoked)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 30.days.from_now
  end
end
