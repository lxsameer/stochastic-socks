require_relative "coder"
require "eventmachine"

class ServerConn < EventMachine::Connection
  attr_accessor :server

  def receive_data data
    @server.send_data data
  end
end

module Server
  def post_init
    @c = Coder.new
    @buf = ''
  end

  def send_data data
    return if data.empty?
    @c.encode data do |seg|
      super(seg) if !seg.empty?
    end
  end

  def receive_data data
    if @buf
      @c.decode data do |seg|
        @buf << seg if !seg.empty?
      end
      if i = @buf.index("\n")
        host, port = @buf[0..i].strip.split(':')
        @conn = EM.connect host, (port && !port.empty? ? port.to_i : 80), ServerConn
        @conn.server = self
        @conn.send_data @buf[(i+1)..-1]
        @buf = nil
      end
    else
      @c.decode data do |seg|
        @conn.send_data seg if !seg.empty?
      end
    end
  rescue
    puts [$!, $!.backtrace]
    close_connection
  end

  def unbind
    @conn.close_connection
  end
end

EM.run do
  puts "starting server at #{CONFIG['server_port']}"
  EM.start_server '127.0.0.1', CONFIG['server_port'], Server
end
