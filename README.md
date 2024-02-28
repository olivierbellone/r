# R

[![Build Status](https://github.com/olivierbellone/r/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/olivierbellone/r/actions?query=branch%3Amain)
[![YARD Docs](https://img.shields.io/badge/yard-docs-blue?logo=readthedocs)](https://olivierbellone.github.io/r/)

R is an experimental Ruby gem which brings Rust's [`Result`](https://doc.rust-lang.org/std/result/) type to Ruby, using [Sorbet](https://sorbet.org/) as the type system.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add r --github=https://github.com/olivierbellone/r

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install specific_install
    $ gem specific_install https://github.com/olivierbellone/r.git

## Usage

`R::Result` is a type used for returning and propagating recoverable errors. (For non-recoverable errors, exceptions should be used instead.)

`R::Result` is an abstract interface with only two possible concrete types: `R::Ok`, representing success and containing a value, and `R::Err`, representing error and containing an error value.

A simple method returning `R::Result` might be defined and used like so:

```ruby
class Version < T::Enum
  enums do
    Version1 = new
    Version2 = new
  end
end

sig { params(header: String).returns(R::Result[Version, String]) }
def parse_version(header)
  return R.err("invalid header length") if header.size != 1

  case header
  when "1"
    R.ok(Version::Version1)
  when "2"
    R.ok(Version::Version2)
  else
    R.err("invalid version")
  end
end

version = parse_version("1")
case version
when R::Ok
  puts "working with version: #{version.ok}"
when R::Err
  puts "error parsing header: #{version.err}"
end
```

`R::Result` is powered by Sorbet, and thus in most cases it is possible to statically assert the types of values contained by `R::Result` instances. In the example above:

```ruby
version = parse_version("1")
case version
when R::Ok
  T.reveal_type(version.ok) # => Version
when R::Err
  T.reveal_type(version.err) # => String
end
```

### API

Refer to the [YARD docs](https://olivierbellone.github.io/r/) for the full API documentation.

In general, I have tried to stick to the Rust `Result` API as closely as possible. Some notable differences are:
- [`inspect`](https://doc.rust-lang.org/std/result/enum.Result.html#method.inspect) is renamed to [`#on_ok`](https://olivierbellone.github.io/r/R/Result.html#on_ok-instance_method), in order not to interfere with the [`#inspect`](https://olivierbellone.github.io/r/R/Result.html#inspect-instance_method) method available on all Ruby objects
- [`inspect_err`](https://doc.rust-lang.org/std/result/enum.Result.html#method.inspect_err) is renamed to [`#on_err`](https://olivierbellone.github.io/r/R/Result.html#on_err-instance_method) to be consistent with the above
- several methods that don't make sense in Ruby are missing (`as_deref`, etc.)
- some methods have slightly different type signatures, to account for the differences in Rust's and Ruby's type systems

### Returning early on errors

When writing code that calls many functions that return `R::Result`s, the error handling can be tedious.

Rust has the question mark operator [`?`](https://doc.rust-lang.org/std/result/#the-question-mark-operator-) to hide some of the boilerplate of propagating errors up the call stack.

I haven't figured out a way to reproduce this specific feature in Ruby, but it is possible to approximate it by using the `#or_else` and `#unwrap_or_else` methods and leveraging the fact that calling `return` within a block will return from the method that created the block.

So you could replace this:

```ruby
class Info < T::Struct
  const :name, String
  const :age, Integer
  const :rating, Integer
end

# Silly method to simulate Rust's `File::create`.
sig { params(name: String).returns(R::Result[File, StandardError]) }
def file_create(name)
  R.ok(File.open(name, "w"))
rescue StandardError => e
  R.err(e)
end

# Another silly method to simulate Rust's `file.write_all`.
sig { params(file: File, data: String).returns(R::Result[NilClass, StandardError]) }
def file_write_all(file, data)
  file.write(data)
  R.ok(nil)
rescue StandardError => e
  R.err(e)
end

sig { params(info: Info).returns(R::Result[NilClass, StandardError]) }
def write_info(info)
  result = file_create("my_best_friends.txt")
  case result
  when R::Ok
    file = result.ok
  else
    return R.err(result.err)
  end

  result = file_write_all(file, "name: #{info.name}\n")
  return R.err(result.err) if result.is_a?(R::Err)

  result = file_write_all(file, "age: #{info.age}\n")
  return R.err(result.err) if result.is_a?(R::Err)

  result = file_write_all(file, "rating: #{info.rating}\n")
  return R.err(result.err) if result.is_a?(R::Err)

  R.ok(nil)
end
```

with this:

```ruby
class Info < T::Struct
  const :name, String
  const :age, Integer
  const :rating, Integer
end

# Silly method to simulate Rust's `File::create`.
sig { params(name: String).returns(R::Result[File, StandardError]) }
def file_create(name)
  R.ok(File.open(name, "w"))
rescue StandardError => e
  R.err(e)
end

# Another silly method to simulate Rust's `file.write_all`.
sig { params(file: File, data: String).returns(R::Result[NilClass, StandardError]) }
def file_write_all(file, data)
  file.write(data)
  R.ok(nil)
rescue StandardError => e
  R.err(e)
end

sig { params(info: Info).returns(R::Result[NilClass, StandardError]) }
def write_info(info)
  file = file_create("my_best_friends.txt").unwrap_or_else { |e| return R.err(e) }
  file_write_all(file, "name: #{info.name}\n").or_else { |e| return R.err(e) }
  file_write_all(file, "age: #{info.age}\n").or_else { |e| return R.err(e) }
  file_write_all(file, "rating: #{info.rating}\n").or_else { |e| return R.err(e) }
  R.ok(nil)
end
```

If you think it's possible to implement something closer to Rust's `?`, I'd love to hear about it! Feel free to open an issue or PR to start a discussion.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/olivierbellone/r. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/olivierbellone/r/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TestGem project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/olivierbellone/r/blob/master/CODE_OF_CONDUCT.md).
