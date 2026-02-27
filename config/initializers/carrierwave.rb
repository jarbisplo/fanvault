CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     Rails.application.credentials.aws[:access_key_id],
    aws_secret_access_key: Rails.application.credentials.aws[:secret_access_key],
    region:                ENV.fetch('AWS_REGION', 'us-east-1')
  }
  config.fog_directory  = ENV['AWS_BUCKET']
  config.fog_public     = false   # All files private — served via signed URLs
  config.fog_attributes = { 'Cache-Control' => 'max-age=315576000' }
  config.storage        = :fog

  if Rails.env.test?
    config.storage    = :file
    config.enable_processing = false
    config.root = Rails.root.join('tmp', 'test_uploads')
  end
end
