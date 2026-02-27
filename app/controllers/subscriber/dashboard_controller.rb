module Subscriber
  class DashboardController < Subscriber::BaseController
    def index
      @subscriptions    = current_user.subscriptions.active.includes(:creator, :plan)
      @subscribed_creators = @subscriptions.map(&:creator)
      @recent_videos    = Video.published
                               .where(creator: @subscribed_creators)
                               .recent
                               .limit(12)
    end
  end
end
