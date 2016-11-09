class Api::WeixinController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:wx_callback]
  before_action :valid_weixin_signature, only: [:wx, :wx_callback]

  def wx
    render text: param_echostr
  end

  def wx_callback
    render text: 'success'

    to_user = params[:xml][:FromUserName].to_s

    # 微信消息推送
    if params[:xml][:MsgType] == 'text'
      content = params[:xml][:Content].to_s
      if content == '二维码'
        qr_code = Weixin.qr_code('123456')
        media_id = Weixin.upload_tmp_image(qr_code)
        Weixin.send_image_custom(to_user, media_id)
      elsif content == '录入'
        Weixin.send_artices(to_user)
      elsif content == '模板'
        Weixin.send_template(to_user)
      else
        Weixin.send_text_custom(to_user, '只能发送“二维码” 和 “录入” 和 “模板”')
      end
    # 微信事件
    elsif params[:xml][:MsgType] == 'event'
      # 扫码事件
      if params[:xml][:Event] == 'SCAN'
        key = params[:xml][:EventKey]
        Weixin.send_text_custom(to_user, "#{Setting.domain}#{api_weixin_index_path(:key => key)}")
      elsif params[:xml][:Event] == 'LOCATION'
        Weixin.send_text_custom(to_user, "维度：#{params[:xml][:Latitude]} 经度：#{params[:xml][:Longitude]}")
      elsif params[:xml][:Event] == 'CLICK'
        key = params[:xml][:EventKey]
        case key
          when 'V1001_TODAY_MUSIC'
            res = 'http://music.163.com/'
          when 'V1001_GOOD'
            res = '谢谢点赞！！！'
          else
            res = '到黑洞了'
        end
        Weixin.send_text_custom(to_user, res)
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