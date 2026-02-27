# == Schema Information
# id, creator_id, name, description, price_cents, interval (month/year),
# stripe_price_id, active, created_at, updated_at

class Plan < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :subscriptions

  enum :interval, { monthly: 0, yearly: 1 }

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :creator, presence: true

  scope :active, -> { where(active: true) }

  def price
    price_cents / 100.0
  end

  def formatted_price
    "$#{'%.2f' % price} / #{interval}"
  end
end
