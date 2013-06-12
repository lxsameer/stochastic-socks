require_relative "coder"
require "rspec"
require "rspec/autorun"

RSpec.configure do |config|
  config.expect_with :stdlib
end

describe Coder do
  before :each do
    @c = Coder.new
  end

  it "encode/decodes" do
    t1 = "hello" * 100
    t2 = "world" * 100
    ptext = ''

    ctext = ''
    @c.encode t1 do |seg|
      ctext << seg
    end

    @c.decode ctext do |seg|
      ptext << seg
    end

    ctext = ''
    @c.encode t2 do |seg|
      ctext << seg
    end

    @c.decode ctext do |seg|
      ptext << seg
    end

    assert_equal t1 + t2, ptext
  end
end
