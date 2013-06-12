# coding: binary

# ref:
#   http://tools.ietf.org/html/rfc1928
#   http://tools.ietf.org/html/rfc1929
#   http://en.wikipedia.org/wiki/SOCKS

require "eventmachine"
require "ipaddr"
require "zscan"
require_relative "coder"

class LocalConn < EventMachine::Connection
  attr_accessor :server

  def post_init
    @c = Coder.new
  end

  def send_enc_data data
    return if data.empty?
    @c.encode data do |seg|
      send_data(seg) if !seg.empty?
    end
  end

  def receive_data data
    @c.decode data do |seg|
      server.send_data seg if !seg.empty?
    end
  end

  def unbind
    server.close_connection_after_writing
  end
end

module Local
  def post_init
    @data = ZScan.new ''.b
    @f = Fiber.new do
      greeting
      loop{ do_cmd }
    end
  end

  def receive_data data
    if @data
      @data << data
      if @f.resume
        @data = nil
        @f = nil
        close_connection
      end
    else
      # tunneling
      @conn.send_enc_data data
    end
  rescue
    puts [$!, $!.backtrace]
    @conn.close_connection
    close_connection
  end

  def unbind
    @conn.close_connection
  end

  private

  REPLY = Hash[{
    success: 0,
    general_failure: 1,
    host_unreachable: 4,
    cmd_not_supported: 7,
    atype_not_supported: 8
  }.map{|k, v| [k, "\x05\x00\x00\x01#{[v].pack 'C'}\x00\x00\x00\x00\x00\x00"] }]

  def greeting
    wait 2
    ver, nmethods = @data.unpack 'CC'
    if ver != 5
      panic "\x05\xFF" # no acceptable auth methods
    end

    wait nmethods
    @data.pos += nmethods
    send_data "\x05\0" # no auth needed
  end

  def do_cmd
    wait 5
    _, cmd, _, atype, domain_len = @data.unpack 'C5'

    case atype
    when 1, 4    # 1: ip v4, 4 bytes, 4: ip v6, 16 bytes
      @data.pos -= 1
      ip_len = 4 * atype
      wait ip_len + 2
      host = IPAddr.ntop @data.byteslice ip_len
      port = @data.unpack('S>').first
    when 3       # domain name
      wait domain_len + 2
      host = @data.byteslice domain_len
      port = @data.unpack('S>').first
    else
      panic REPLY[:atype_not_supported]
    end

    case cmd
    when 1
      send_data REPLY[:success]
      puts "#{cmd}: #{host}:#{port}"
      @conn = EventMachine.connect CONFIG['server'], CONFIG['server_port'], LocalConn
      @conn.server = self
      @conn.send_enc_data "#{host}:#{port}\n"
      @conn.send_enc_data @data.rest
      @data = nil
      Fiber.yield
    when 2, 3 # bind, udp
      # send_data "\x05\x00\x00\x01" + IPAddr.new(host).hton + [port].pack('n')
      panic REPLY[:cmd_not_supported]
    else
      panic REPLY[:cmd_not_supported]
    end
  end

  def wait n
    Fiber.yield until @data.rest_bytesize >= n
  end

  def panic data
    send_data data
    Fiber.yield true
  end
end

if __FILE__ == $PROGRAM_NAME
  EM.run do
    puts "starting socks5 at #{CONFIG['local']}:#{CONFIG['local_port']}"
    EM.start_server CONFIG['local'], CONFIG['local_port'], Local
  end
end
