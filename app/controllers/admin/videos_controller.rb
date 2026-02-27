module Admin
  class VideosController < Admin::BaseController
    before_action :set_video, only: [:edit, :update, :destroy, :publish, :unpublish]

    def index
      @videos = Video.recent.page(params[:page]).per(20)
    end

    def new
      @video = Video.new
    end

    def create
      @video = Video.new(video_params)
      @video.creator = current_user
      @video.status  = :draft

      if @video.save
        redirect_to admin_videos_path, notice: 'Video uploaded successfully!'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @video.update(video_params)
        redirect_to admin_videos_path, notice: 'Video updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @video.destroy
      redirect_to admin_videos_path, notice: 'Video deleted.'
    end

    def publish
      @video.update!(status: :published)
      redirect_back fallback_location: admin_videos_path, notice: 'Video is now live!'
    end

    def unpublish
      @video.update!(status: :draft)
      redirect_back fallback_location: admin_videos_path, notice: 'Video set to draft.'
    end

    private

    def set_video
      @video = Video.find(params[:id])
    end

    def video_params
      params.require(:video).permit(:title, :description, :video_file, :thumbnail)
    end
  end
end
