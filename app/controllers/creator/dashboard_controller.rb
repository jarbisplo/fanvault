module Creator
  class DashboardController < Creator::BaseController
    def index
      @videos_count     = current_user.videos.count
      @published_count  = current_user.videos.published.count
      @subscribers_count = current_user.creator_subscriptions.active.count
      @recent_videos    = current_user.videos.recent.limit(5)
      @recent_subs      = current_user.creator_subscriptions.active.includes(:subscriber).limit(5)
      @plans            = current_user.plans.active
    end
  end
end
