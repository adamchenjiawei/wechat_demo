class Api::WeixinController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:wx_callback]
  before_action :valid_weixin_signature, only: [:wx, :wx_callback]

  def wx
    render text: param_echostr
  end

  def wx_callback
    render text: 'success'

    to_user = params[:xml][:FromUserName].to_s

    if params[:xml][:MsgType] == 'text'
      content = params[:xml][:Content].to_s
      if content == '二维码'
        qr_code = Weixin.qr_code('123456')
        media_id = Weixin.upload_tmp_image(qr_code)
        Weixin.send_image_custom(to_user, media_id)
      else
        Weixin.send_text_custom(to_user, '只能发送“二维码”')
      end
    else params[:xml][:MsgType] == 'event'
      if params[:xml][:Event] == 'SCAN'
        key = params[:xml][:EventKey]
        Weixin.send_text_custom(to_user, "#{Setting.domain}#{api_weixin_index_path(:key => key)}")
      end
    end
  end

  def index
    user_agent = request.user_agent
    # 判断是否在微信客户端
    if user_agent.to_s.include?('MicroMessenger')
      if (code = params[:code]).blank? && params[:state].blank?
        url = "#{Setting.domain}#{api_weixin_index_path(:key => params[:key].to_s)}"
        redirect_to "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{Setting.app_id}&redirect_uri=#{url}&response_type=code&scope=snsapi_userinfo&state=123#wechat_redirect"
        return false
      else
        res = RestClient.get "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{Setting.app_id}&secret=#{Setting.app_secret}&code=#{code}&grant_type=authorization_code"
        if res.code.to_i == 200
          hash = JSON.parse(res.body)
          open_id = hash['openid']
          access_token = hash['access_token']

          userinfo = RestClient.get "https://api.weixin.qq.com/sns/userinfo?access_token=#{access_token}&openid=#{open_id}&lang=zh_CN"
          @nickname = JSON.parse(userinfo.body)['nickname']
        end
      end
    end

    render layout: false
  end

  private

  def valid_weixin_signature
    signature = Weixin.signature(param_timestamp, param_nonce)
    unless param_signature == signature
      render text: 'false' and return
    end
  end

  def param_timestamp
    params[:timestamp].to_s
  end

  def param_nonce
    params[:nonce].to_s
  end

  def param_signature
    params[:signature].to_s
  end

  def param_echostr
    params[:echostr].to_s
  end

  def param_openid
    params[:openid].to_s
  end


end