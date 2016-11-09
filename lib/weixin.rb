class Weixin


  # 签名算法
  def self.signature(timestamp, nonce_str)
    tmp_arr = [Setting.token, timestamp, nonce_str].sort!
    tmp_str = tmp_arr.join('')
    Digest::SHA1.hexdigest(tmp_str)
  end

  # 通过weixin_authorize gem获取access_token
  # access_token时间设置为微信接口返回的expires_in
  def self.access_token
    $wx_client.get_access_token
  end

  # 获取二维码的图片地址
  def self.qr_code(scene)
    code = $wx_client.create_qr_scene(scene, 1800)
    $wx_client.qr_code_url(code.result['ticket'])
  end

  # 上传临时图片资源
  def self.upload_tmp_image(image_file_or_path)
    if http?(image_file_or_path)
      image_name = Digest::SHA1.hexdigest(image_file_or_path)
      f = File.open(save_image("#{image_name}_#{Time.now.to_i}.jpeg", image_file_or_path))
    else
      f = image_file_or_path
    end
    res = $wx_client.upload_media(f, "image")
    res.result['media_id']
  end

  # 下载二维码图片资源
  def self.save_image(image_name, img_url)
    File.open("/tmp/#{image_name}", 'wb'){|f| f.write(open(img_url).read)}
    "/tmp/#{image_name}"
  end

  def self.http?(uri)
    return false if !uri.is_a?(String)
    uri = URI.parse(uri)
    uri.scheme =~ /^https?$/
  end

  # 发送图片客服消息
  def self.send_image_custom(to_user, media_id)
    $wx_client.send_image_custom(to_user, media_id)
  end

  # 发送文本客服消息
  def self.send_text_custom(to_user, content)
    $wx_client.send_text_custom(to_user, content)
  end

  # 创建菜单
  def self.create_menu
    menu =  {
        "button":[
            {
                "type":"click",
                "name":"今日歌曲",
                "key":"V1001_TODAY_MUSIC"
            },
            {
                "name":"菜单",
                "sub_button":[
                    {
                        "type":"view",
                        "name":"搜索",
                        "url":"http://www.soso.com/"
                    },
                    {
                        "type":"view",
                        "name":"视频",
                        "url":"http://v.qq.com/"
                    },
                    {
                        "type":"click",
                        "name":"赞一下我们",
                        "key":"V1001_GOOD"
                    }]
            }]
    }
    $wx_client.create_menu(menu)
  end

  # 发送图文消息
  def self.send_artices(to_user)
    articles = [
        {
            "title":"Happy Day",
            "description":"Is Really A Happy Day",
            "url":"#{Setting.domain}/api/weixin",
            "picurl":"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=4289595768,39600692&fm=116&gp=0.jpg"
        },
        {
            "title":"Happy Day",
            "description":"Is Really A Happy Day",
            "url":"#{Setting.domain}/api/weixin",
            "picurl":"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=4289595768,39600692&fm=116&gp=0.jpg"
        }
    ]
    $wx_client.send_news_custom(to_user, articles)
  end

  # 微信接口post请求
  def self.weixin_post(api_url, post_body, url_params)
    $wx_client.http_post(api_url, post_body, url_params, WeixinAuthorize::CUSTOM_ENDPOINT)
  end

  # 微信发送模板消息
  def self.send_template(to_user)
    post_body =     {
        "touser":"#{to_user}",
        "template_id":"yNUEicRY4M2svw394mgS34TgUwRgSkBIbLD2X8Q2AkQ",
        "url":"http://weixin.qq.com/download",
        "data":{
            "result": {
                "value":"恭喜你，",
                "color":"#173177"
            },
            "withdrawMoney":{
                "value":"500万",
                "color":"#173177"
            },
            "withdrawTime": {
                "value":"2016-11-10 23:59:59",
                "color":"#173177"
            },
            "cardInfo": {
                "value":"1万",
                "color":"#173177"
            },
            "arrivedTime":{
                "value":"2016-11-11 11:11:11",
                "color":"#173177"
            },
            "remark":{
                "value":"2016-11-11 12:12:12",
                "color":"#173177"
            }
        }
    }
    weixin_post(Setting['weixin.send_tmeplate_msg'], post_body, {})
  end
end