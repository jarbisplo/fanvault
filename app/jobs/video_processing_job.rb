class VideoProcessingJob < ApplicationJob
  queue_as :videos
  sidekiq_options retry: 3

  QUALITIES = [
    { name: '480p',  scale: 'scale=-2:480',  vb: '800k',  ab: '128k' },
    { name: '720p',  scale: 'scale=-2:720',  vb: '2500k', ab: '128k' },
    { name: '1080p', scale: 'scale=-2:1080', vb: '5000k', ab: '192k' }
  ].freeze

  def perform(video_id)
    @video = Video.find(video_id)
    return unless @video.processing?

    Dir.mktmpdir("fanvault_#{video_id}_") do |tmpdir|
      original_path = File.join(tmpdir, 'original.mp4')

      # 1. Download original from S3 (or local dev path)
      download_original(@video, original_path)

      # 2. Extract metadata
      duration = extract_duration(original_path)
      @video.update_column(:duration_seconds, duration) if duration

      # 3. Generate thumbnail at 5s (or 10% into video)
      unless @video.thumbnail.present?
        thumb_time = [5, (duration.to_i * 0.1).to_i].min.clamp(1, duration.to_i)
        thumb_path = File.join(tmpdir, 'thumbnail.jpg')
        generate_thumbnail(original_path, thumb_path, thumb_time)
        if File.exist?(thumb_path) && File.size(thumb_path) > 0
          @video.thumbnail = File.open(thumb_path)
          @video.save!
        end
      end

      # 4. Transcode to HLS
      hls_dir = File.join(tmpdir, 'hls')
      FileUtils.mkdir_p(hls_dir)
      master_playlist = transcode_hls(original_path, hls_dir, @video)

      # 5. Upload HLS to S3 and save master URL
      if master_playlist
        hls_url = upload_hls_to_s3(hls_dir, @video)
        @video.update_column(:hls_url, hls_url) if hls_url
      end

      @video.update_column(:status, Video.statuses[:published])
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "VideoProcessingJob: video #{video_id} not found"
  rescue => e
    Rails.logger.error "VideoProcessingJob failed for #{video_id}: #{e.class} — #{e.message}"
    @video&.update_column(:status, Video.statuses[:draft])
    raise
  end

  private

  # ── Download ────────────────────────────────────────────────────
  def download_original(video, dest_path)
    source_url = video.video_file.url
    if source_url.start_with?('http')
      # S3 signed URL — stream download
      URI.open(source_url) { |src| IO.copy_stream(src, dest_path) }
    else
      # Local dev — just copy
      local = Rails.root.join('public', video.video_file.current_path.to_s.sub(%r{^/}, ''))
      FileUtils.cp(local.to_s, dest_path)
    end
  end

  # ── Metadata ────────────────────────────────────────────────────
  def extract_duration(path)
    out = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{path}" 2>/dev/null`.strip
    out.to_f.round if out.present? && out.to_f > 0
  end

  # ── Thumbnail ───────────────────────────────────────────────────
  def generate_thumbnail(video_path, thumb_path, time_secs)
    system(
      'ffmpeg', '-y', '-ss', time_secs.to_s,
      '-i', video_path,
      '-frames:v', '1',
      '-vf', 'scale=1280:-2',
      '-q:v', '4',
      thumb_path,
      out: '/dev/null', err: '/dev/null'
    )
  end

  # ── HLS transcode ───────────────────────────────────────────────
  def transcode_hls(input_path, hls_dir, video)
    streams      = []
    stream_maps  = []
    idx          = 0

    QUALITIES.each do |q|
      q_dir = File.join(hls_dir, q[:name])
      FileUtils.mkdir_p(q_dir)
      playlist = File.join(q_dir, 'playlist.m3u8')

      streams += [
        '-map', '0:v:0', '-map', '0:a:0',
        "-filter:v:#{idx}", q[:scale],
        "-c:v:#{idx}", 'libx264', "-b:v:#{idx}", q[:vb], "-maxrate:#{idx}", q[:vb], "-bufsize:#{idx}", (q[:vb].to_i * 2).to_s + 'k',
        "-c:a:#{idx}", 'aac', "-b:a:#{idx}", q[:ab],
        "-hls_time", '6',
        "-hls_playlist_type", 'vod',
        "-hls_segment_filename", File.join(q_dir, 'seg_%04d.ts'),
        "-hls_flags", 'independent_segments',
        playlist
      ]

      stream_maps << "v:#{idx},a:#{idx},name:#{q[:name]}"
      idx += 1
    end

    args = ['ffmpeg', '-y', '-i', input_path, '-preset', 'fast'] + streams
    success = system(*args, out: '/dev/null', err: '/dev/null')
    return nil unless success

    # Write master playlist
    master_path = File.join(hls_dir, 'master.m3u8')
    File.open(master_path, 'w') do |f|
      f.puts '#EXTM3U'
      f.puts '#EXT-X-VERSION:3'
      QUALITIES.each do |q|
        bandwidth = q[:vb].to_i * 1000
        f.puts "#EXT-X-STREAM-INF:BANDWIDTH=#{bandwidth},RESOLUTION=#{q[:name]}"
        f.puts "#{q[:name]}/playlist.m3u8"
      end
    end

    master_path
  end

  # ── Upload HLS to S3 ────────────────────────────────────────────
  def upload_hls_to_s3(hls_dir, video)
    return nil unless ENV['AWS_ACCESS_KEY_ID'].present?

    require 'aws-sdk-s3'
    s3 = Aws::S3::Resource.new(
      region:      ENV.fetch('AWS_REGION', 'us-east-1'),
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
    bucket     = s3.bucket(ENV['AWS_BUCKET'])
    key_prefix = "uploads/videos/#{video.creator_id}/#{video.id}/hls"
    master_url = nil

    Dir.glob("#{hls_dir}/**/*").each do |local_path|
      next if File.directory?(local_path)
      relative   = local_path.sub("#{hls_dir}/", '')
      s3_key     = "#{key_prefix}/#{relative}"
      content_type = local_path.end_with?('.m3u8') ? 'application/x-mpegURL' : 'video/MP2T'

      obj = bucket.object(s3_key)
      obj.upload_file(local_path, acl: 'private', content_type: content_type)
      master_url = obj.public_url if relative == 'master.m3u8'
    end

    # Return a signed URL for the master playlist (or store key and sign on request)
    "#{key_prefix}/master.m3u8"
  end
end
