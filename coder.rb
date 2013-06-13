# coding: binary
require "openssl"
require "yaml"

if $config
  CONFIG = $config # for test
else
  CONFIG = YAML.load_file File.dirname(__FILE__) + '/config.yml'
end
KEY_LEN = CONFIG['cipher'][/\d+/].to_i / 8
CONFIG['key'] = CONFIG['key'].ljust(KEY_LEN, '*')[0...KEY_LEN]
CONFIG['local_port'] = CONFIG['local_port'].to_i
CONFIG['server_port'] = CONFIG['server_port'].to_i
raise "delimiter too short, need at least 12 bytes: #{CONFIG['delim']}" if CONFIG['delim'].size < 12

class PlainCoder
  IV_MAX = 36 ** KEY_LEN
  DELIM = CONFIG['delim'].force_encoding('utf-8').encode('gb18030').force_encoding('binary')

  def initialize
    @buf = ''
  end

  def encode data
    yield data
    yield CONFIG['text']
  end

  def decode data
    @buf << data
    loop do
      fore, rest = @buf.split(DELIM, 2)
      break unless rest
      yield fore
      @buf = rest
    end
  end
end

class Coder < PlainCoder

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
    yield DELIM
  end

  def decode data
    @buf << data
    loop do
      fore, rest = @buf.split DELIM, 2
      break unless rest
      @decoder.iv = fore.byteslice 0...KEY_LEN
      yield @decoder.update fore.byteslice KEY_LEN..-1
      yield @decoder.final
      @buf = rest
    end
  end
end
