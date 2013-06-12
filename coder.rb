# coding: binary
require "openssl"
require "yaml"

CONFIG = YAML.load_file File.dirname(__FILE__) + '/config.yml'
KEY_LEN = CONFIG['cipher'][/\d+/].to_i / 8
IV_MAX = 36 ** KEY_LEN
CONFIG['key'] = CONFIG['key'].ljust(KEY_LEN, '*')[0...KEY_LEN]
CONFIG['local_port'] = CONFIG['local_port'].to_i
CONFIG['server_port'] = CONFIG['server_port'].to_i

class Coder
  XTEXT = "学习十八大精神,建设和谐社会".force_encoding('utf-8').encode('gbk').force_encoding('binary')

  def initialize
    @buf = '' # for decode state

    @encoder = OpenSSL::Cipher.new CONFIG['cipher']
    @encoder.encrypt
    @encoder.key = CONFIG['key']

    @decoder = OpenSSL::Cipher.new CONFIG['cipher']
    @decoder.decrypt
    @decoder.key = CONFIG['key']
  end

  def encode data
    iv = rand(IV_MAX).to_s(36).ljust KEY_LEN
    @encoder.iv = iv
    yield iv
    yield @encoder.update(data)
    yield @encoder.final
    yield XTEXT
  end

  def decode data
    @buf << data
    while (i = @buf.index XTEXT)
      @decoder.iv = @buf[0...KEY_LEN]
      yield @decoder.update(@buf[KEY_LEN...i])
      yield @decoder.final
      @buf = @buf[(i + XTEXT.bytesize)...-1]
    end
  end
end
