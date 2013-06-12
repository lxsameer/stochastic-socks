# Install

```bash
gem ins eventmachine
cp config.yml.example config.yml
vi config.yml
```

# Use

Server

```bash
nohup ruby server.rb > log &
```

Local

```bash
ruby local.rb
```

# Test

Prepare config.yml and `gem ins rspec`, then `ruby coder_spec.rb`.
