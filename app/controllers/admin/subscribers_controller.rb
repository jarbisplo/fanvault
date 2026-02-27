module Admin
  class SubscribersController < Admin::BaseController
    def index
      @subscribers = Subscription.active.includes(:subscriber).recent.page(params[:page]).per(25)
    end
  end
end
