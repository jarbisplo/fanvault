class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Pay gem for Stripe subscriptions
  pay_customer

  has_many :videos, foreign_key: :creator_id, dependent: :destroy
  has_many :subscriptions, foreign_key: :subscriber_id, dependent: :destroy

  mount_uploader :avatar, AvatarUploader

  validates :first_name, :last_name, presence: true

  def admin?
    admin == true
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def active_subscriber?
    subscriptions.active.exists?
  end

  def can_watch?
    admin? || active_subscriber?
  end
end
