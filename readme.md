# Intro

Socks 5 tunnel with a bit crypto / obsfucation.

For every data chunk, a random initial vector is generated, which grants the stochastic behavior.

A delimiter is inserted after the ciphered data chunk, it helps decoding and may be used to perform [poison attack](http://arxiv.org/pdf/1206.6389.pdf) on machine learning routers in the future.

# Install

Requires [Ruby](ruby-lang.org) 1.9+

```bash
gem ins zscan
gem ins eventmachine
cp config.yml.example config.yml
vi config.yml
```

# Use

You need a server

```bash
ruby server.rb
```

Then on local

```bash
ruby local.rb
```

# Test

Prepare gems used by test

```bash
gem ins rspec
gem ins pry
```

Then

```bash
ruby spec.rb
```
