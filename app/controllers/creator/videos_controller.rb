module Creator
  class VideosController < Creator::BaseController
    before_action :set_video, only: [:show, :edit, :update, :destroy, :publish, :archive]

    def index
      @videos = current_user.videos.recent.page(params[:page]).per(20)
    end

    def new
      @video = current_user.videos.build
    end

    def create
      @video = current_user.videos.build(video_params)
      @video.status = :processing

      if @video.save
        redirect_to creator_video_path(@video), notice: 'Video uploaded! Processing in background.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @video.update(video_params)
        redirect_to creator_video_path(@video), notice: 'Video updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @video.destroy
      redirect_to creator_videos_path, notice: 'Video removed.'
    end

    def publish
      @video.update!(status: :published)
      redirect_back fallback_location: creator_videos_path, notice: 'Video published!'
    end

    def archive
      @video.update!(status: :archived)
      redirect_back fallback_location: creator_videos_path, notice: 'Video archived.'
    end

    private

    def set_video
      @video = current_user.videos.find(params[:id])
    end

    def video_params
      params.require(:video).permit(:title, :description, :video_file, :thumbnail, :visibility)
    end
  end
end
