class VideosController < ApplicationController
  before_action :authenticate_user!
  before_action :require_access!

  def index
    @videos = Video.published.recent.page(params[:page]).per(12)
  end

  def show
    @video = Video.published.find(params[:id])
    @video.increment_views!
  end

  private

  def require_access!
    unless current_user.can_watch?
      redirect_to pricing_path, alert: 'Subscribe to access the videos.'
    end
  end
end
