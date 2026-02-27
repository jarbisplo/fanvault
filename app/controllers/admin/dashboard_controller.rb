module Admin
  class DashboardController < Admin::BaseController
    def index
      @videos_count     = Video.count
      @published_count  = Video.published.count
      @subscribers_count = Subscription.active.count
      @recent_videos    = Video.recent.limit(8)
    end
  end
end
