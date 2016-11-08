class Setting < RailsSettings::Base
  source "#{Rails.root}/config/weixin.yml"
  namespace Rails.env
end
