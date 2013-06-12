# coding: binary
require_relative "coder"
require "eventmachine"
require "logger"

if __FILE__ == $PROGRAM_NAME
  LOGGER = Logger.new File.dirname(__FILE__) + '/log'
else
  LOGGER = Logger.new $stdout
end

class ServerConn < EventMachine::Connection
  attr_accessor :server

  def receive_data data
    @server.send_enc_data data
  end

  def unbind
    @server.close_connection_after_writing
  end
end

class Server < EventMachine::Connection
  def post_init
    @c = Coder.new
    @buf = ''
  end

  def send_enc_data data
    return if data.empty?
    @c.encode data do |seg|
      send_data(seg) if !seg.empty?
    end
  rescue
    LOGGER.error [$!, $!.backtrace]
  end

  def receive_data data
    if @buf
      @c.decode data do |seg|
        @buf << seg
      end
      host, rest = @buf.split "\n", 2
      if rest
        domain, port = host.split ':'
        LOGGER.info host
        @conn = EM.connect domain, (port && !port.empty? ? port.to_i : 80), ServerConn
        @conn.server = self
        @conn.send_data rest if !rest.empty?
        @buf = nil
      end
    else
      @c.decode data do |seg|
        @conn.send_data seg if !seg.empty?
      end
    end
  rescue
    LOGGER.error [$!, $!.backtrace]
    @conn.close_connection if @conn
    close_connection
  end

  def unbind
    @conn.close_connection if @conn
  end
end

if __FILE__ == $PROGRAM_NAME
  Process.daemon
  EM.run do
    LOGGER.info "starting server at 0.0.0.0:#{CONFIG['server_port']}"
    EM.start_server '0.0.0.0', CONFIG['server_port'], Server
  end
end
