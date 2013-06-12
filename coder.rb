# coding: binary
require "openssl"
require "yaml"

if $config
  CONFIG = $config
else
  CONFIG = YAML.load_file File.dirname(__FILE__) + '/config.yml'
end
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
      raise 'i < key_len' if i < KEY_LEN
      @decoder.iv = @buf.byteslice 0...KEY_LEN
      yield @decoder.update @buf.byteslice KEY_LEN...i
      yield @decoder.final
      @buf = @buf.byteslice (i + XTEXT.bytesize)...-1
      @buf = '' unless @buf
    end
  end
end
