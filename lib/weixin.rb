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
    "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{code.result['ticket']}"
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
end