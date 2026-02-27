class VideoUploader < CarrierWave::Uploader::Base
  storage :fog

  def store_dir
    "uploads/videos/#{model.creator_id}/#{model.id}"
  end

  def extension_allowlist
    %w[mp4 mov avi mkv webm m4v]
  end

  def size_range
    0..5.gigabytes
  end

  # Generate a time-limited signed URL for private S3 objects
  def url(*args)
    if fog_credentials[:provider] == 'AWS'
      file.url(expires: 3600) # 1 hour signed URL
    else
      super
    end
  end
end
