class VideoProcessingJob < ApplicationJob
  queue_as :videos
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  ALL_QUALITIES = [
    { name: '1080p', height: 1080, scale: 'scale=-2:1080', vb: '4000k', ab: '192k' },
    { name: '720p',  height: 720,  scale: 'scale=-2:720',  vb: '2500k', ab: '128k' },
    { name: '480p',  height: 480,  scale: 'scale=-2:480',  vb: '800k',  ab: '128k' }
  ].freeze

  def perform(video_id)
    @video = Video.find(video_id)

    Dir.mktmpdir("fanvault_#{video_id}_") do |tmpdir|
      original_path = File.join(tmpdir, 'original.mp4')

      # 1. Download original
      download_original(@video, original_path)
      Rails.logger.info "[VideoJob] Downloaded #{video_id} to #{original_path} (#{File.size(original_path) / 1_000_000}MB)"

      # 2. Probe: duration + source resolution (don't upscale)
      meta          = probe(original_path)
      duration      = meta[:duration]
      source_height = meta[:height]
      @video.update_column(:duration_seconds, duration) if duration

      # 3. Thumbnail at 5s (or 10% in)
      unless @video.thumbnail.present?
        seek = [[5, (duration.to_i * 0.1).to_i].max, [duration.to_i - 1, 1].max].min
        thumb_path = File.join(tmpdir, 'thumbnail.jpg')
        generate_thumbnail(original_path, thumb_path, seek)
        if File.exist?(thumb_path) && File.size(thumb_path) > 0
          @video.thumbnail = File.open(thumb_path)
          @video.save!(validate: false)
        end
      end

      # 4. Only transcode tiers that are ≤ source resolution
      qualities = ALL_QUALITIES.select { |q| source_height.nil? || q[:height] <= source_height }
      qualities = [ALL_QUALITIES.last] if qualities.empty? # always at least 480p

      # 5. HLS transcode
      hls_dir = File.join(tmpdir, 'hls')
      FileUtils.mkdir_p(hls_dir)
      transcode_hls(original_path, hls_dir, qualities)
      master_path = write_master_playlist(hls_dir, qualities)

      # 6. Upload HLS to S3
      hls_key = upload_hls_to_s3(hls_dir, @video)

      # 7. Delete original from S3 to save storage
      delete_original_from_s3(@video) if hls_key.present?

      # 8. Mark published
      @video.update_columns(hls_url: hls_key, status: Video.statuses[:published])
      Rails.logger.info "[VideoJob] #{video_id} complete — HLS at #{hls_key}"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[VideoJob] Video #{video_id} not found"
  rescue => e
    Rails.logger.error "[VideoJob] #{video_id} failed: #{e.class} — #{e.message}"
    @video&.update_column(:status, Video.statuses[:draft])
    raise
  end

  private

  # ── Download ──────────────────────────────────────────────────────
  def download_original(video, dest_path)
    source_url = video.video_file.url
    if source_url.start_with?('http')
      require 'open-uri'
      URI.open(source_url, 'rb') { |src| IO.copy_stream(src, dest_path) }
    else
      local = Rails.root.join('public', video.video_file.current_path.to_s.sub(%r{^/}, ''))
      FileUtils.cp(local.to_s, dest_path)
    end
  end

  # ── Probe ─────────────────────────────────────────────────────────
  def probe(path)
    duration_raw = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{path}" 2>/dev/null`.strip
    height_raw   = `ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "#{path}" 2>/dev/null`.strip
    {
      duration: duration_raw.to_f > 0 ? duration_raw.to_f.round : nil,
      height:   height_raw.to_i > 0   ? height_raw.to_i         : nil
    }
  end

  # ── Thumbnail ────────────────────────────────────────────────────
  def generate_thumbnail(video_path, thumb_path, time_secs)
    system(
      'ffmpeg', '-y', '-ss', time_secs.to_s, '-i', video_path,
      '-frames:v', '1', '-vf', 'scale=1280:-2', '-q:v', '4',
      thumb_path, out: '/dev/null', err: '/dev/null'
    )
  end

  # ── HLS transcode ────────────────────────────────────────────────
  def transcode_hls(input_path, hls_dir, qualities)
    qualities.each do |q|
      q_dir = File.join(hls_dir, q[:name])
      FileUtils.mkdir_p(q_dir)
      playlist = File.join(q_dir, 'playlist.m3u8')

      success = system(
        'ffmpeg', '-y', '-i', input_path,
        '-vf', q[:scale],
        '-c:v', 'libx264', '-preset', 'fast', '-crf', '23',
        '-b:v', q[:vb], '-maxrate', q[:vb], '-bufsize', (q[:vb].to_i * 2).to_s + 'k',
        '-c:a', 'aac', '-b:a', q[:ab],
        '-hls_time', '6',
        '-hls_playlist_type', 'vod',
        '-hls_segment_filename', File.join(q_dir, 'seg_%04d.ts'),
        '-hls_flags', 'independent_segments',
        playlist,
        out: '/dev/null', err: '/dev/null'
      )

      Rails.logger.info "[VideoJob] #{q[:name]} transcode #{success ? 'OK' : 'FAILED'}"
    end
  end

  # ── Master playlist ──────────────────────────────────────────────
  def write_master_playlist(hls_dir, qualities)
    master_path = File.join(hls_dir, 'master.m3u8')
    File.open(master_path, 'w') do |f|
      f.puts '#EXTM3U'
      f.puts '#EXT-X-VERSION:3'
      qualities.each do |q|
        bandwidth = q[:vb].to_i * 1000
        f.puts "#EXT-X-STREAM-INF:BANDWIDTH=#{bandwidth},RESOLUTION=#{q[:name]}"
        f.puts "#{q[:name]}/playlist.m3u8"
      end
    end
    master_path
  end

  # ── Upload HLS to S3 ────────────────────────────────────────────
  def upload_hls_to_s3(hls_dir, video)
    return nil unless ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_ACCESS_KEY_ID'] != 'placeholder'

    require 'aws-sdk-s3'
    s3     = Aws::S3::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1'))
    bucket = ENV['AWS_BUCKET']
    prefix = "uploads/videos/#{video.creator_id}/#{video.id}/hls"

    Dir.glob("#{hls_dir}/**/*").sort.each do |local_path|
      next if File.directory?(local_path)
      relative     = local_path.sub("#{hls_dir}/", '')
      s3_key       = "#{prefix}/#{relative}"
      content_type = local_path.end_with?('.m3u8') ? 'application/x-mpegURL' : 'video/MP2T'

      File.open(local_path, 'rb') do |f|
        s3.put_object(bucket: bucket, key: s3_key, body: f, content_type: content_type)
      end
    end

    "#{prefix}/master.m3u8"
  end

  # ── Delete original from S3 ─────────────────────────────────────
  def delete_original_from_s3(video)
    return unless ENV['AWS_ACCESS_KEY_ID'].present? && ENV['AWS_ACCESS_KEY_ID'] != 'placeholder'
    return unless video.video_file.present?

    require 'aws-sdk-s3'
    s3  = Aws::S3::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1'))
    key = video.video_file.path
    return if key.blank?

    s3.delete_object(bucket: ENV['AWS_BUCKET'], key: key)
    Rails.logger.info "[VideoJob] Deleted original from S3: #{key}"
  rescue => e
    Rails.logger.warn "[VideoJob] Could not delete original: #{e.message}"
  end
end
