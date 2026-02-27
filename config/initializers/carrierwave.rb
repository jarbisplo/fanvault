CarrierWave.configure do |config|
  if Rails.env.production? || ENV['AWS_ACCESS_KEY_ID'].present?
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID', ''),
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', ''),
      region:                ENV.fetch('AWS_REGION', 'us-east-1')
    }
    config.fog_directory  = ENV.fetch('AWS_BUCKET', 'fanvault')
    config.fog_public     = false
    config.fog_attributes = { 'Cache-Control' => 'max-age=315576000' }
    config.storage        = :fog
  else
    # Development fallback: store locally
    config.storage = :file
    config.root    = Rails.root.join('public')
    config.cache_dir = Rails.root.join('tmp', 'uploads')
  end

  if Rails.env.test?
    config.storage    = :file
    config.enable_processing = false
    config.root = Rails.root.join('tmp', 'test_uploads')
  end
end
