class VideosController < ApplicationController
  before_action :set_creator
  before_action :set_video

  def show
    unless @video.accessible_by?(current_user)
      redirect_to creator_profile_path(@creator.username),
                  alert: 'Subscribe to watch this video.' and return
    end

    @video.increment_views!
    VideoView.find_or_create_by(video: @video, user: current_user) if user_signed_in?
  end

  private

  def set_creator
    @creator = User.creators.find_by!(username: params[:username])
  end

  def set_video
    @video = @creator.videos.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to creator_profile_path(@creator.username), alert: 'Video not found.'
  end
end
