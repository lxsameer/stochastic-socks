# Intro

Socks 5 tunnel with a bit crypto / obfuscation.

For every data chunk, a random initial vector is generated, which grants the stochastic behavior.

A delimiter is inserted after the ciphered data chunk, it helps decoding and may be used to perform [poison attack](http://arxiv.org/pdf/1206.6389.pdf) on machine learning routers in the future.

It is in principle very similar to [shadowsocks](https://github.com/clowwindy/shadowsocks) but with only 1/3 LOC because it's Ruby. And it's easier to change the cipher scheme for your own purpose.

# Install

Requires [Ruby](http://ruby-lang.org) 1.9.2+ and an OS X / BSD / Linux server

```bash
git clone git@github.com:luikore/stochastic-socks.git
cd stochastic-socks
gem ins zscan
gem ins eventmachine
cp config.yml.example config.yml
# edit config
vi config.yml
```

Available ciphers:

```
aes-128-cbc aes-128-ecb
aes-192-cbc aes-192-ecb
aes-256-cbc aes-256-ecb
```

# Use

On server

```bash
ruby server.rb
```

On local

```bash
ruby local.rb
```

# Test

Prepare gems

```bash
gem ins rspec
gem ins pry
```

Then

```bash
ruby spec.rb
```

# Hacking the transport layer

You can change `coder.rb`, reimplement encode/decode with your own cipher scheme.
