Pay.setup do |config|
  config.business_name = "FanVault"
  config.business_address = ""
  config.application_name = "FanVault"
  config.support_email = "support@fanvault.dev"
  config.default_product_name = "FanVault Subscription"
  config.automount_routes = true
  config.routes_path = "/pay"
end
