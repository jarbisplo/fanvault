# == Schema Information
# id, email, encrypted_password, first_name, last_name, username,
# bio, avatar, role :string (creator/subscriber), created_at, updated_at

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  rolify

  # Associations
  # As creator
  has_many :videos, foreign_key: :creator_id, dependent: :destroy
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: :creator_id, dependent: :destroy
  has_many :creator_subscriptions, class_name: 'Subscription', foreign_key: :creator_id, dependent: :destroy

  # As subscriber
  has_many :subscriptions, foreign_key: :subscriber_id, dependent: :destroy
  has_many :subscribed_creators, through: :subscriptions, source: :creator
  has_many :received_invitations, class_name: 'Invitation', foreign_key: :subscriber_id

  # Pay gem (Stripe)
  pay_customer

  mount_uploader :avatar, AvatarUploader

  validates :username, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true

  scope :creators, -> { with_role(:creator) }
  scope :subscribers, -> { with_role(:subscriber) }

  def creator?
    has_role?(:creator)
  end

  def subscriber?
    has_role?(:subscriber)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def can_watch?(video)
    return true if self == video.creator
    active_subscription_for?(video.creator)
  end

  def active_subscription_for?(creator)
    subscriptions.active.where(creator: creator).exists?
  end
end
