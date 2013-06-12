# coding: binary
require_relative "coder"
require "eventmachine"

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
  end

  def receive_data data
    if @buf
      @c.decode data do |seg|
        @buf << seg if !seg.empty?
      end
      if i = @buf.index("\n")
        host, port = @buf.byteslice(0...i).strip.split(':')
        puts "connect: #{host}:#{port}"
        @conn = EM.connect host, (port && !port.empty? ? port.to_i : 80), ServerConn
        @conn.server = self
        @buf = @buf.byteslice (i+1)..-1
        @conn.send_data @buf if @buf and !@buf.empty?
        @buf = nil
      end
    else
      @c.decode data do |seg|
        @conn.send_data seg if !seg.empty?
      end
    end
  rescue
    puts [$!, $!.backtrace]
    @conn.close_connection
    close_connection
  end

  def unbind
    @conn.close_connection
  end
end

if __FILE__ == $PROGRAM_NAME
  EM.run do
    puts "starting server at 0.0.0.0:#{CONFIG['server_port']}"
    EM.start_server '0.0.0.0', CONFIG['server_port'], Server
  end
end
