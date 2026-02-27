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

  def hls_proxy
    @video = Video.published.find(params[:id])
    hls_path = params[:hls_path]

    prefix = @video.hls_url.sub('/master.m3u8', '')
    s3_key = "#{prefix}/#{hls_path}"

    Rails.logger.info "[HLS] #{request.user_agent&.split(' ')&.first} → #{s3_key}"

    signed_url = generate_signed_url(s3_key)
    return head :not_found unless signed_url

    if hls_path.end_with?('.m3u8')
      # Stream m3u8 content so hls.js resolves relative URLs against our proxy,
      # not against the S3 domain (which would bypass signing → 403).
      require 'net/http'
      uri  = URI.parse(signed_url)
      body = Net::HTTP.get(uri)
      render plain: body, content_type: 'application/vnd.apple.mpegurl'
    else
      # .ts segments are binary — a redirect to a signed URL is fine.
      redirect_to signed_url, allow_other_host: true, status: :found
    end
  end

  private

  def require_access!
    unless current_user.can_watch?
      redirect_to pricing_path, alert: 'Subscribe to access the videos.'
    end
  end

  def generate_signed_url(s3_key, expires: 3600)
    return nil unless ENV['AWS_ACCESS_KEY_ID'].present?
    require 'aws-sdk-s3'
    signer = Aws::S3::Presigner.new(
      client: Aws::S3::Client.new(
        region:      ENV.fetch('AWS_REGION', 'us-east-1'),
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
      )
    )
    signer.presigned_url(:get_object, bucket: ENV['AWS_BUCKET'], key: s3_key, expires_in: expires)
  rescue => e
    Rails.logger.error "HLS sign failed for #{s3_key}: #{e.message}"
    nil
  end
end
