class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Allow login with username OR email
  attr_writer :login

  def login
    @login || username || email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login
      where(conditions).where(
        "lower(username) = :val OR lower(email) = :val",
        val: login.downcase
      ).first
    else
      where(conditions).first
    end
  end

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
