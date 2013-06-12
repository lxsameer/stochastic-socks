# coding: binary
require "rspec"
require "rspec/autorun"
require "pry"
RSpec.configure do |config|
  config.expect_with :stdlib
end

$config = {
  'cipher' => 'aes-256-cbc',
  'key' => 'nopassword',
  'local_port' => 8081,
  'server' => '127.0.0.1',
  'server_port' => 8082
}

require_relative "coder"
describe Coder do
  before :each do
    @c = Coder.new
  end

  3.times do
    m = 1 + (rand 420)
    n = 1 + (rand 220)
    it "encode/decodes 'hello' * #{m} + 'world' * #{n}" do
      t1 = "hello" * m
      t2 = "world" * n
      ptext = ''

      @c.encode t1 do |seg|
        @c.decode seg[0...1] do |x|
          ptext << x
        end
        if seg.bytesize > 1
          @c.decode seg[1..-1] do |x|
            ptext << x
          end
        end
      end

      @c.encode t2 do |seg|
        @c.decode seg do |x|
          ptext << x
        end
      end

      assert_equal t1 + t2, ptext
    end
  end
end

require_relative "local"
require_relative "server"
describe [Local, Server] do
  before :all do
    @servers = fork do
      EM.run do
        EM.start_server '127.0.0.1', CONFIG['local_port'], Local
        EM.start_server '127.0.0.1', CONFIG['server_port'], Server
      end
    end
    @httpd = fork do
      exec *%w'ruby -run -e httpd -- . --port=8083', out: '/dev/null', err: '/dev/null'
    end
    trap :INT do
      Process.kill :KILL, @servers
      Process.kill :KILL, @httpd
    end
    sleep 1 # wait for servers to startup
  end

  after :all do
    Process.kill :KILL, @servers
    Process.kill :KILL, @httpd
  end

  %w[127.0.0.1:8083/spec.rb baidu.com https://www.google-analytics.com/ga.js].each do |url|
    it "transmission #{url}" do
      b = `curl -s #{url}`
      a = `curl -s #{url} --socks5 127.0.0.1:#{CONFIG['local_port']}`
      assert_equal b.size, a.size
      assert_equal b, a
    end
  end
end
