class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Redirect to Stripe checkout
    plan = Plan.active.first
    unless plan&.stripe_price_id.present?
      redirect_to pricing_path, alert: 'Subscription not yet configured. Coming soon!' and return
    end

    checkout = current_user.payment_processor.checkout(
      mode: 'subscription',
      line_items: [{ price: plan.stripe_price_id, quantity: 1 }],
      success_url: videos_url + '?subscribed=1',
      cancel_url: pricing_url
    )

    redirect_to checkout.url, allow_other_host: true
  end
end
