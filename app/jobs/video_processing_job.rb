class VideoProcessingJob < ApplicationJob
  queue_as :videos
  sidekiq_options retry: 3

  def perform(video_id)
    video = Video.find(video_id)
    return unless video.processing?

    # In production: extract duration + generate thumbnail from video file
    # Requires ffmpeg on the server
    extract_metadata(video)
    generate_thumbnail(video) unless video.thumbnail.present?
    video.update!(status: :published)

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "VideoProcessingJob: video #{video_id} not found"
  rescue => e
    Rails.logger.error "VideoProcessingJob failed for #{video_id}: #{e.message}"
    video&.update!(status: :draft)
    raise
  end

  private

  def extract_metadata(video)
    # ffprobe to get duration
    # url = video.video_file.url
    # ... parse duration_seconds
  end

  def generate_thumbnail(video)
    # ffmpeg to extract frame at 5s mark, upload as thumbnail
  end
end
