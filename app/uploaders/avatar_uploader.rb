class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  def store_dir
    "uploads/avatars/#{model.id}"
  end

  version :thumb do
    process resize_to_fill: [100, 100]
  end

  version :profile do
    process resize_to_fill: [300, 300]
  end

  def extension_allowlist
    %w[jpg jpeg png webp gif]
  end

  def default_url(*args)
    '/assets/default_avatar.png'
  end
end
