class VideosController < ApplicationController
  before_action :authenticate_user!
  before_action :require_access!

  def index
    @featured   = Video.published.recent.first
    @categories = Video::CATEGORY_LABELS.map do |key, label|
      videos = Video.published.where(category: key).recent.limit(8)
      [key, label, videos] unless videos.empty?
    end.compact
    @uncategorized = Video.published.where(category: nil).recent.limit(8)
  end

  def show
    @video   = Video.published.find(params[:id])
    @video.increment_views!
    @up_next = Video.published.where.not(id: @video.id)
                    .where(category: @video.category)
                    .recent.limit(4)
    @up_next = Video.published.where.not(id: @video.id).recent.limit(4) if @up_next.empty?
  end

  private

  def require_access!
    unless current_user.can_watch?
      redirect_to pricing_path, alert: 'Subscribe to access the videos.'
    end
  end
end
