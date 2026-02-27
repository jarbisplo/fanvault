class ThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  def store_dir
    "uploads/thumbnails/#{model.creator_id}/#{model.id}"
  end

  version :large do
    process resize_to_fill: [1280, 720]
  end

  version :medium do
    process resize_to_fill: [640, 360]
  end

  version :small do
    process resize_to_fill: [320, 180]
  end

  def extension_allowlist
    %w[jpg jpeg png webp]
  end
end
