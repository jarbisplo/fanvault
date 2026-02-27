module Subscriber
  class BaseController < ApplicationController
    before_action :authenticate_user!
    layout 'subscriber'
  end
end
