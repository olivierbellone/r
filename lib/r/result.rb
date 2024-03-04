# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

require_relative "unwrap_failed_error"

module R
  # {Result} is a type that represents either success ({Ok}) or failure ({Err}).
  #
  # @see R::Ok
  # @see R::Err
  module Result
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    include Kernel

    interface!
    sealed!

    # The type of the success value.
    OkType = type_member(:out)

    # The type of the error value.
    ErrType = type_member(:out)

    # Returns `true` if `self` and `other` are both {Ok} and `self.ok == other.ok`, or if
    # `self` and `other` are both {Err} and `self.err == other.err`.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x == R.ok(2) # => true
    #   x == R.ok(3) # => false
    #   x == R.err("not Ok") # => false
    #   x == "not Result" # => false
    #
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x == R.ok(2) # => false
    #   x == R.err("Some error message") # => true
    #   x == R.err("Different error message") # => false
    #   x == "not Result" # => false
    #
    # @see R::Ok#==
    # @see R::Err#==
    sig { abstract.params(other: T.anything).returns(T::Boolean) }
    def ==(other); end

    # Returns a string representation of `self`.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.inspect # => "R.ok(-3)"
    #
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.inspect # => "R.err(\"Some error message\")"
    #
    # @see R::Ok#inspect
    # @see R::Err#inspect
    sig { abstract.returns(String) }
    def inspect; end

    # Returns `true` if the result is {Ok}.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.ok? # => true
    #
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.ok? # => false
    #
    # @see R::Ok#ok?
    # @see R::Err#ok?
    sig { abstract.returns(T::Boolean) }
    def ok?; end

    # Returns `true` if the result is {Ok} and the value inside of it matches a predicate.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => true
    #
    #   x = T.let(R.ok(0), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => false
    #
    #   x = T.let(R.err("hey"), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => false
    #
    # @see R::Ok#ok_and?
    # @see R::Err#ok_and?
    sig { abstract.params(blk: T.proc.params(value: OkType).returns(T::Boolean)).returns(T::Boolean) }
    def ok_and?(&blk); end

    # Returns `true` if the result is {Err}.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.err? # => false
    #
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.err? # => true
    #
    # @see R::Ok#err?
    # @see R::Err#err?
    sig { abstract.returns(T::Boolean) }
    def err?; end

    # Returns `true` if the result is {Err} and the value inside of it matches a predicate.
    #
    # @example
    #   x = T.let(R.err(ArgumentError.new), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => true
    #
    #   x = T.let(R.err(IOError.new), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => false
    #
    #   x = T.let(R.ok(123), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => false
    #
    # @see R::Ok#err_and?
    # @see R::Err#err_and?
    sig { abstract.params(blk: T.proc.params(value: ErrType).returns(T::Boolean)).returns(T::Boolean) }
    def err_and?(&blk); end

    # Returns the value if the result is {Ok}, or `nil` if the result is {Err}.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.ok => 2
    #
    #   x = T.let(R.err("Nothing here"), R::Result[Integer, String])
    #   x.ok => nil
    #
    # @see R::Ok#ok
    # @see R::Err#ok
    sig { abstract.returns(T.nilable(OkType)) }
    def ok; end

    # Returns the value if the result is {Err}, or `nil` if the result is {Ok}.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.err => nil
    #
    #   x = T.let(R.err("Nothing here"), R::Result[Integer, String])
    #   x.err => "Nothing here"
    #
    # @see R::Ok#err
    # @see R::Err#err
    sig { abstract.returns(T.nilable(ErrType)) }
    def err; end

    # Maps a {Result}`[T, E]` to {Result}`[U, E]` by applying a function to a contained {Ok} value, leaving an {Err}
    # value untouched.
    #
    # This function can be used to compose the results of two functions.
    #
    # @example
    #   sig { params(str: String).returns(R::Result[Integer, String]) }
    #   def parse_int(str)
    #     R.ok(Integer(str))
    #   rescue ArgumentError
    #     R.err("Cannot parse #{str} as an integer")
    #   end
    #
    #   out = T.let([], T::Array[Integer])
    #   text = "1\n2\nHi\n4\n"
    #   text.lines.each do |num|
    #     res = parse_int(num).map { |i| i * 2 }
    #     case res
    #     when R::Ok
    #       out << res.ok
    #     when R::Err
    #       # do nothing
    #     end
    #   end
    #   out # => [2, 4, 8]
    #
    # @see R::Ok#map
    # @see R::Err#map
    sig do
      abstract
        .type_parameters(:U)
        .params(blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)))
        .returns(Result[T.type_parameter(:U), ErrType])
    end
    def map(&blk); end

    # Returns the provided default (if {Err}), or applies a function to the contained value (if {Ok}).
    #
    # Arguments passed to {#map_or} are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {#map_or_else}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R.ok("foo"), R::Result[String, String])
    #   x.map_or(42) { |v| v.size } # => 3
    #
    #   x = T.let(R.err("bar"), R::Result[String, String])
    #   x.map_or(42) { |v| v.size } # => 42
    #
    # @see R::Ok#map_or
    # @see R::Err#map_or
    sig do
      abstract
        .type_parameters(:U)
        .params(
          default: T.type_parameter(:U),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or(default, &blk); end

    # Maps a {Result}`[T, E]` to `U` by applying fallback function `default` to a contained {Err} value, or function
    # `f` to a contained {Ok} value.
    #
    # This function can be used to unpack a successful result while handling an error.
    #
    # @example
    #   k = 21
    #
    #   x = T.let(R.ok("foo"), R::Result[String, String])
    #   x.map_or_else(->(e) { k * 2 }) { |v| v.size } # => 3
    #
    #   x = T.let(R.err("bar"), R::Result[Integer, String])
    #   x.map_or_else(->(e) { k * 2 }) { |v| v.size } # => 42
    #
    # @see R::Ok#map_or_else
    # @see R::Err#map_or_else
    sig do
      abstract
        .type_parameters(:U)
        .params(
          default: T.proc.params(value: ErrType).returns(T.type_parameter(:U)),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or_else(default, &blk); end

    # Maps a {Result}`[T, E]` to {Result}`[T, F]` by applying a function to a contained {Err} value, leaving an {Ok}
    # value untouched.
    #
    # This function can be used to pass through a successful result while handling an error.
    #
    # @example
    #   sig { params(x: Integer).returns(String) }
    #   def stringify(x)
    #     "error code: #{x}"
    #   end
    #
    #   x = T.let(R.ok(2), R::Result[Integer, Integer])
    #   x.map_err { |x| stringify(x) } # => R.ok(2)
    #
    #   x = T.let(R.err(13), R::Result[Integer, Integer])
    #   x.map_err { |x| stringify(x) } # => R.err("error code: 13")
    #
    # @see R::Ok#map_err
    # @see R::Err#map_err
    sig do
      abstract
        .type_parameters(:F)
        .params(blk: T.proc.params(value: ErrType).returns(T.type_parameter(:F)))
        .returns(Result[OkType, T.type_parameter(:F)])
    end
    def map_err(&blk); end

    # Calls the provided block with the contained value (if {Ok}).
    #
    # @example
    #   msg = T.let(nil, T.nilable(String))
    #   x = T.let(R.ok("42"), R::Result[String, String])
    #   x
    #     .on_ok  { |x| msg = "Success! #{x}" }
    #     .on_err { |x| msg = "Failure! #{x}" }
    #   msg # => "Success! 42"
    #
    # @see R::Ok#on_ok
    # @see R::Err#on_ok
    sig { abstract.params(blk: T.proc.params(value: OkType).void).returns(T.self_type) }
    def on_ok(&blk); end

    # Calls the provided block with the contained error (if {Err}).
    #
    # @example
    #   msg = T.let(nil, T.nilable(String))
    #   x = T.let(R.err("ohno"), R::Result[String, String])
    #   x
    #     .on_ok  { |x| msg = "Success! #{x}" }
    #     .on_err { |x| msg = "Failure! #{x}" }
    #   msg # => "Failure! ohno"
    #
    # @see R::Ok#on_err
    # @see R::Err#on_err
    sig { abstract.params(blk: T.proc.params(value: ErrType).void).returns(T.self_type) }
    def on_err(&blk); end

    # Returns the contained {Ok} value, or raises an {UnwrapFailedError} if the result is {Err}.
    #
    # Because this function may raise an exception, its use is generally discouraged. Instead, prefer to use pattern
    # matching and {#ok}, or call {#unwrap_or} or {#unwrap_or_else}.
    #
    # @raise [UnwrapFailedError] if the result is {Err}, with a message including the passed message, and the content
    #   of the {Err} value
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.expect!("Testing expect!") # => 2
    #
    # @example This example raises an {UnwrapFailedError} exception.
    #   x = T.let(R.err("emergency failure"), R::Result[Integer, String])
    #   x.expect!("Testing expect!") # => raise R::UnwrapFailedError.new("Testing expect!", "emergency failure")
    #
    # @see R::Ok#expect!
    # @see R::Err#expect!
    sig { abstract.params(msg: String).returns(OkType) }
    def expect!(msg); end

    # Returns the contained {Ok} value, or raises an {UnwrapFailedError} if the result is {Err}.
    #
    # Because this function may raise an exception, its use is generally discouraged. Instead, prefer to use pattern
    # matching and {#ok}, or call {#unwrap_or} or {#unwrap_or_else}.
    #
    # @raise [UnwrapFailedError] if the result is {Err}, with a custom message provided by the {Err}'s value
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.unwrap! # => 2
    #
    # @example This example raises an {UnwrapFailedError} exception.
    #   x = T.let(R.err("emergency failure"), R::Result[Integer, String])
    #   x.unwrap! # => raise R::UnwrapFailedError.new("called `Result#unwrap!` on an `Err` value", "emergency failure")
    #
    # @see R::Ok#unwrap!
    # @see R::Err#unwrap!
    sig { abstract.returns(OkType) }
    def unwrap!; end

    # Returns the contained {Err} value, or raises an {UnwrapFailedError} if the result is {Ok}.
    #
    # @raise [UnwrapFailedError] if the result is {Ok}, with a message including the passed message, and the content
    #   of the {Ok} value
    #
    # @example This example raises an {UnwrapFailedError} exception.
    #   x = R.ok(10)
    #   x.expect_err!("Testing expect_err!") # => raise R::UnwrapFailedError.new("Testing expect_err!", 10)
    #
    # @see R::Ok#expect_err!
    # @see R::Err#expect_err!
    sig { abstract.params(msg: String).returns(ErrType) }
    def expect_err!(msg); end

    # Returns the contained {Err} value, or raises an {UnwrapFailedError} if the result is {Ok}.
    #
    # @raise [UnwrapFailedError] if the result is {Ok}, with a custom message provided by the {Ok}'s value
    #
    # @example This example raises an {UnwrapFailedError} exception.
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.unwrap_err! # => raise R::UnwrapFailedError.new("called `Result#unwrap_err!` on an `Ok` value", 2)
    #
    # @example
    #   x = T.let(R.err("emergency failure"), R::Result[Integer, String])
    #   x.unwrap_err! # => "emergency failure"
    #
    # @see R::Ok#unwrap_err!
    # @see R::Err#unwrap_err!
    sig { abstract.returns(ErrType) }
    def unwrap_err!; end

    # Returns `res` if the result is {Ok}, otherwise returns the {Err} value of `self`.
    #
    # Arguments passed to `and` are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {and_then}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   y = T.let(R.err("late error"), R::Result[String, String])
    #   x.and(y) # => R.err("late error")
    #
    #   x = T.let(R.err("early error"), R::Result[Integer, String])
    #   y = T.let(R.ok("foo"), R::Result[String, String])
    #   x.and(y) # => R.err("early error")
    #
    #   x = T.let(R.err("not a 2"), R::Result[Integer, String])
    #   y = T.let(R.err("late error"), R::Result[String, String])
    #   x.and(y) # => R.err("not a 2")
    #
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   y = T.let(R.ok("different result type"), R::Result[String, String])
    #   x.and(y) # => R.ok("different result type")
    #
    # @see R::Ok#and
    # @see R::Err#and
    sig do
      abstract
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[T.type_parameter(:U), T.any(ErrType, T.type_parameter(:F))])
    end
    def and(res); end

    # Calls the block if the result is {Ok}, otherwise returns the {Err} value of `self`.
    #
    # This function can be used for control flow based on {Result} values.
    #
    # @example
    #   sig { params(x: Integer).returns(R::Result[String, String])}
    #   def sqrt_then_to_s(x)
    #     return R.err("negative value") if x < 0
    #     R.ok(Math.sqrt(x).to_s)
    #   end
    #
    #   R.ok(4).and_then { |x| sqrt_then_to_s(x) } # => R.ok("2.0")
    #   R.ok(-4).and_then { |x| sqrt_then_to_s(x) } # => R.err("negative value")
    #   R.err("not a number").and_then { |x| sqrt_then_to_s(x) } # => R.err("not a number")
    #
    # @see R::Ok#and_then
    # @see R::Err#and_then
    sig do
      abstract
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: OkType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[T.type_parameter(:U), T.any(ErrType, T.type_parameter(:F))])
    end
    def and_then(&blk); end

    # Returns `res` if the result is {Err}, otherwise returns the {Ok} value of `self`.
    #
    # Arguments passed to `or` are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {or_else}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   y = T.let(R.err("late error"), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    #
    #   x = T.let(R.err("early error"), R::Result[Integer, String])
    #   y = T.let(R.ok(2), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    #
    #   x = T.let(R.err("not a 2"), R::Result[Integer, String])
    #   y = T.let(R.err("late error"), R::Result[Integer, String])
    #   x.or(y) # => R.err("late error")
    #
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   y = T.let(R.ok(100), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    #
    # @see R::Ok#or
    # @see R::Err#or
    sig do
      abstract
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[T.any(OkType, T.type_parameter(:U)), T.type_parameter(:F)])
    end
    def or(res); end

    # Calls the block if the result is {Err}, otherwise returns the {Ok} value of `self`.
    #
    # This function can be used for control flow based on {Result} values.
    #
    # @example
    #   sig { params(x: Integer).returns(R::Result[Integer, Integer])}
    #   def sq(x)
    #     R.ok(x * x)
    #   end
    #
    #   sig { params(x: Integer).returns(R::Result[Integer, Integer])}
    #   def err_(x)
    #     R.err(x)
    #   end
    #
    #   R.ok(2).or_else { |x| sq(x) }.or_else { |x| sq(x) } # => R.ok(2)
    #   R.ok(2).or_else { |x| err_(x) }.or_else { |x| sq(x) } # => R.ok(2)
    #   R.err(3).or_else { |x| sq(x) }.or_else { |x| err_(x) } # => R.ok(9)
    #   R.err(3).or_else { |x| err_(x) }.or_else { |x| err_(x) } # => R.err(3)
    #
    # @see R::Ok#or_else
    # @see R::Err#or_else
    sig do
      abstract
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: ErrType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[T.any(OkType, T.type_parameter(:U)), T.type_parameter(:F)])
    end
    def or_else(&blk); end

    # Returns the contained {Ok} value or a provided default.
    #
    # Arguments passed to `unwrap_or` are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {unwrap_or_else}, which is lazily evaluated.
    #
    # @example
    #   default = 2
    #
    #   x = T.let(R.ok(9), R::Result[Integer, String])
    #   x.unwrap_or(default) # => 9
    #
    #   x = T.let(R.err("error"), R::Result[Integer, String])
    #   x.unwrap_or(default) # => 2
    #
    # @see R::Ok#unwrap_or
    # @see R::Err#unwrap_or
    sig do
      abstract
        .type_parameters(:DefaultType)
        .params(default: T.type_parameter(:DefaultType))
        .returns(T.any(OkType, T.type_parameter(:DefaultType)))
    end
    def unwrap_or(default); end

    # Returns the contained {Ok} value or computes it from a closure.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.unwrap_or_else(&:size) # => 2
    #
    #   x = T.let(R.err("foo"), R::Result[Integer, String])
    #   x.unwrap_or_else(&:size) # => 3
    #
    # @see R::Ok#unwrap_or_else
    # @see R::Err#unwrap_or_else
    sig do
      abstract
        .type_parameters(:DefaultType)
        .params(blk: T.proc.params(arg: ErrType).returns(T.type_parameter(:DefaultType)))
        .returns(T.any(OkType, T.type_parameter(:DefaultType)))
    end
    def unwrap_or_else(&blk); end

    # Returns the contained {Ok} value or calls the block with the {Err} value.
    #
    # This method is similar to {#unwrap_or_else}, but in case of an {Err} value, the block must short-circuit by
    # either calling `return` (which will return from the enclosing method) or raising an exception.
    #
    # This is useful to make error handling less tedious when dealing with many methods returning results.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.try? { |e| return e } # => 2
    #
    #   x = T.let(R.err("foo"), R::Result[Integer, String])
    #   x.try? { |e| return e } # => return R.err("foo")
    #
    # @see R::Ok#try?
    # @see R::Err#try?
    #
    # @see R::Result#unwrap_or_else
    # @see R::Ok#unwrap_or_else
    # @see R::Err#unwrap_or_else
    sig do
      abstract
        .params(blk: T.proc.params(arg: Err[ErrType]).returns(T.noreturn))
        .returns(OkType)
    end
    def try?(&blk); end
  end

  sig(:final) { type_parameters(:T).params(value: T.type_parameter(:T)).returns(Ok[T.type_parameter(:T)]) }
  def self.ok(value)
    Ok.new(value)
  end

  # Contains the success value.
  #
  # @see R::Result
  # @see R::Err
  class Ok
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    include Result

    final!

    # The type of the success value.
    OkType = type_member

    # The type of the error value.
    #
    # In the context of an {Ok} value, this is set to [`T.noreturn`](https://sorbet.org/docs/noreturn).
    # This enables Sorbet to detect potential dead code paths.
    ErrType = type_member { { fixed: T.noreturn } }

    # Returns `true` if `other` is {Ok} and `self.ok == other.ok`.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x == R.ok(2) # => true
    #   x == R.ok(3) # => false
    #   x == R.err("not Ok") # => false
    #   x == "not Result" # => false
    #
    # @see R::Result#==
    # @see R::Err#==
    sig(:final) { override.params(other: T.anything).returns(T::Boolean) }
    def ==(other)
      case other
      when Ok
        other.ok == @value
      else
        false
      end
    end

    # Returns a string representation of `self`.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.inspect # => "R.ok(-3)"
    #
    # @see R::Result#inspect
    # @see R::Err#inspect
    sig(:final) { override.returns(String) }
    def inspect
      value_repr = case @value
      when Object
        @value.inspect
      else
        "<uninspectable value>"
      end
      "R.ok(#{value_repr})"
    end

    sig(:final) do
      type_parameters(:T)
        .params(value: T.type_parameter(:T))
        .returns(T.all(T.attached_class, Ok[T.type_parameter(:T)]))
    end
    def self.new(value)
      super
    end

    sig(:final) { params(value: OkType).void }
    def initialize(value)
      @value = value
    end

    # Returns `true`.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.ok? # => true
    #
    # @see R::Result#ok?
    # @see R::Err#ok?
    sig(:final) { override.returns(TrueClass) }
    def ok?
      true
    end

    # Returns `true` if value matches a predicate.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => true
    #
    #   x = T.let(R.ok(0), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => false
    #
    # @see R::Result#ok_and?
    # @see R::Err#ok_and?
    sig(:final) { override.params(blk: T.proc.params(value: OkType).returns(T::Boolean)).returns(T::Boolean) }
    def ok_and?(&blk)
      yield(@value)
    end

    # Returns `false`.
    #
    # @example
    #   x = T.let(R.ok(-3), R::Result[Integer, String])
    #   x.err? # => false
    #
    # @see R::Result#err?
    # @see R::Err#err?
    sig(:final) { override.returns(FalseClass) }
    def err?
      false
    end

    # Returns `false`.
    #
    # @example
    #   x = T.let(R.ok(123), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => false
    #
    # @see R::Result#err_and?
    # @see R::Err#err_and?
    sig(:final) { override.params(blk: T.proc.params(value: ErrType).returns(T::Boolean)).returns(FalseClass) }
    def err_and?(&blk)
      false
    end

    # Returns the value.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.ok => 2
    #
    # @see R::Result#ok
    # @see R::Err#ok
    sig(:final) { override.returns(OkType) }
    def ok
      @value
    end

    # Returns `nil`.
    #
    # @example
    #   x = T.let(R.ok(2), R::Result[Integer, String])
    #   x.err => nil
    #
    # @see R::Result#err
    # @see R::Err#err
    sig(:final) { override.returns(NilClass) }
    def err
      nil
    end

    # Maps a {Result}`[T, E]` to {Result}`[U, E]` by applying a function to the contained value.
    #
    # This function can be used to compose the results of two functions.
    #
    # @see R::Result#map
    # @see R::Err#map
    sig(:final) do
      override
        .type_parameters(:U)
        .params(blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)))
        .returns(Ok[T.type_parameter(:U)])
    end
    def map(&blk)
      Ok.new(yield(@value))
    end

    # Applies a function to the contained value.
    #
    # Arguments passed to {#map_or} are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {#map_or_else}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R.ok("foo"), R::Result[String, String])
    #   x.map_or(42) { |v| v.size } # => 3
    #
    # @see R::Result#map_or
    # @see R::Err#map_or
    sig(:final) do
      override
        .type_parameters(:U)
        .params(
          default: T.type_parameter(:U),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or(default, &blk)
      yield(@value)
    end

    # Maps a {Result}`[T, E]` to `U` by applying a function to the contained {Ok} value.
    #
    # This function can be used to unpack a successful result while handling an error.
    #
    # @example
    #   k = 21
    #
    #   x = T.let(R.ok("foo"), R::Result[String, String])
    #   x.map_or_else(->(e) { k * 2 }) { |v| v.size } # => 3
    #
    # @see R::Result#map_or_else
    # @see R::Err#map_or_else
    sig(:final) do
      override
        .type_parameters(:U)
        .params(
          default: T.proc.params(value: ErrType).returns(T.type_parameter(:U)),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or_else(default, &blk)
      yield(@value)
    end

    sig(:final) do
      override
        .type_parameters(:F)
        .params(blk: T.proc.params(value: ErrType).returns(T.type_parameter(:F)))
        .returns(Ok[OkType])
    end
    def map_err(&blk)
      self
    end

    # sig { override.params(blk: T.proc.params(arg: T).returns(T.untyped)).returns(T.self_type) }
    # def each(&blk)
    #   [@value].each(&blk)
    #   self
    # end

    sig(:final) { override.params(msg: String).returns(OkType) }
    def expect!(msg)
      @value
    end

    sig(:final) { override.returns(OkType) }
    def unwrap!
      @value
    end

    sig(:final) { override.params(msg: String).returns(T.noreturn) }
    def expect_err!(msg)
      raise UnwrapFailedError.new(msg, @value)
    end

    sig(:final) { override.returns(T.noreturn) }
    def unwrap_err!
      raise UnwrapFailedError.new("called `Result#unwrap_err!` on an `Ok` value", @value)
    end

    # Returns `res`.
    #
    # @example
    #   x = R::Ok.new(2)
    #   y = R::Err.new("late error")
    #   x.and(y) # => R.err("late error")
    #
    #   x = R::Ok.new(2)
    #   y = R::Ok.new("different result type")
    #   x.and(y) # => R.ok("different result type")
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[T.type_parameter(:U), T.type_parameter(:F)])
    end
    def and(res)
      res
    end

    # Calls the block.
    #
    # @example
    #   sig { params(x: Integer).returns(R::Result[String, String])}
    #   def sqrt_then_to_s(x)
    #     return R::Err.new("negative value") if x < 0
    #     R::Ok.new(Math.sqrt(x).to_s)
    #   end
    #
    #   R::Ok.new(4).and_then { |x| sqrt_then_to_s(x) } # => R.ok("2.0")
    #   R::Ok.new(-4).and_then { |x| sqrt_then_to_s(x) } # => R.err("negative value")
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: OkType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[T.type_parameter(:U), T.type_parameter(:F)])
    end
    def and_then(&blk)
      yield(@value)
    end

    # Returns the {Ok} value of `self`.
    #
    # Arguments passed to `or` are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {or_else}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R::Ok.new(2), R::Result[Integer, String])
    #   y = T.let(R::Err.new("late error"), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    #
    #   x = T.let(R::Err.new("early error"), R::Result[Integer, String])
    #   y = T.let(R::Ok.new(2), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    #
    #   x = T.let(R::Err.new("not a 2"), R::Result[Integer, String])
    #   y = T.let(R::Err.new("late error"), R::Result[Integer, String])
    #   x.or(y) # => R.err("late error")
    #
    #   x = T.let(R::Ok.new(2), R::Result[Integer, String])
    #   y = T.let(R::Ok.new(100), R::Result[Integer, String])
    #   x.or(y) # => R.ok(2)
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[OkType, T.type_parameter(:F)])
    end
    def or(res)
      self
    end

    # Returns the {Ok} value of `self`.
    #
    # This function can be used for control flow based on {Result} values.
    #
    # @example
    #   sig { params(x: Integer).returns(R::Result[Integer, Integer])}
    #   def sq(x)
    #     R::Ok.new(x * x)
    #   end
    #
    #   sig { params(x: Integer).returns(R::Result[Integer, Integer])}
    #   def err_(x)
    #     R::Err.new(x)
    #   end
    #
    #   R::Ok.new(2).or_else { |x| sq(x) }.or_else { |x| sq(x) } # => R.ok(2)
    #   R::Ok.new(2).or_else { |x| err_(x) }.or_else { |x| sq(x) } # => R.ok(2)
    #   R::Err.new(3).or_else { |x| sq(x) }.or_else { |x| err_(x) } # => R.ok(9)
    #   R::Err.new(3).or_else { |x| err_(x) }.or_else { |x| err_(x) } # => R.err(3)
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: ErrType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[OkType, T.type_parameter(:F)])
    end
    def or_else(&blk)
      self
    end

    # Returns the contained {Ok} value.
    #
    # Arguments passed to `unwrap_or` are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {unwrap_or_else}, which is lazily evaluated.
    #
    # @example
    #   default = 2
    #
    #   x = T.let(R::Ok.new(9), R::Result[Integer, String])
    #   x.unwrap_or(default) # => 9
    #
    #   x = T.let(R::Err.new("error"), R::Result[Integer, String])
    #   x.unwrap_or(default) # => 2
    sig(:final) do
      override
        .type_parameters(:DefaultType)
        .params(default: T.type_parameter(:DefaultType))
        .returns(OkType)
    end
    def unwrap_or(default)
      @value
    end

    # Returns the contained {Ok} value.
    #
    # @example
    #   x = T.let(R::Ok.new(2), R::Result[Integer, String])
    #   x.unwrap_or_else(&:size) # => 2
    #
    #   x = T.let(R::Err.new("foo"), R::Result[Integer, String])
    #   x.unwrap_or_else(&:size) # => 3
    sig(:final) do
      override
        .type_parameters(:DefaultType)
        .params(blk: T.proc.params(arg: ErrType).returns(T.type_parameter(:DefaultType)))
        .returns(OkType)
    end
    def unwrap_or_else(&blk)
      @value
    end

    sig(:final) do
      override
        .params(blk: T.proc.params(arg: Err[ErrType]).returns(T.noreturn))
        .returns(OkType)
    end
    def try?(&blk)
      @value
    end

    sig(:final) { override.params(blk: T.proc.params(value: OkType).void).returns(T.self_type) }
    def on_ok(&blk)
      yield(@value)
      self
    end

    sig(:final) { override.params(blk: T.proc.params(value: ErrType).void).returns(T.self_type) }
    def on_err(&blk)
      self
    end
  end

  sig(:final) { type_parameters(:E).params(value: T.type_parameter(:E)).returns(Err[T.type_parameter(:E)]) }
  def self.err(value)
    Err.new(value)
  end

  # Contains the error value.
  #
  # @see R::Result
  # @see R::Ok
  class Err
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    include Result

    final!

    # The type of the success value.
    #
    # In the context of an {Err} value, this is set to [T.noreturn](https://sorbet.org/docs/noreturn).
    # This enables Sorbet to detect potential dead code paths.
    OkType = type_member { { fixed: T.noreturn } }

    # The type of the error value.
    ErrType = type_member

    # Returns `true` if `other` is both {Err} and `self.err == other.err`.
    #
    # @example
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x == R.ok(2) # => false
    #   x == R.err("Some error message") # => true
    #   x == R.err("Different error message") # => false
    #   x == "not Result" # => false
    #
    # @see R::Result#==
    # @see R::Ok#==
    sig(:final) { override.params(other: T.anything).returns(T::Boolean) }
    def ==(other)
      case other
      when Err
        other.err == @value
      else
        false
      end
    end

    # Returns a string representation of `self`.
    #
    # @example
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.inspect # => "R.err(\"Some error message\")"
    #
    # @see R::Result#inspect
    # @see R::Ok#inspect
    sig(:final) { override.returns(String) }
    def inspect
      value_repr = case @value
      when Object
        @value.inspect
      else
        "<uninspectable value>"
      end
      "R.err(#{value_repr})"
    end

    sig(:final) do
      type_parameters(:E)
        .params(value: T.type_parameter(:E))
        .returns(T.all(T.attached_class, Err[T.type_parameter(:E)]))
    end
    def self.new(value)
      super(value)
    end

    sig(:final) { params(value: ErrType).void }
    def initialize(value)
      @value = value
    end

    # Returns `false`.
    #
    # @example
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.ok? # => false
    #
    # @see R::Result#ok?
    # @see R::Ok#ok?
    sig(:final) { override.returns(FalseClass) }
    def ok?
      false
    end

    # Returns `false`.
    #
    # @example
    #   x = T.let(R.err("hey"), R::Result[Integer, String])
    #   x.ok_and? { |x| x > 1 } # => false
    #
    # @see R::Result#ok_and?
    # @see R::Ok#ok_and?
    sig(:final) { override.params(blk: T.proc.params(value: OkType).returns(T::Boolean)).returns(FalseClass) }
    def ok_and?(&blk)
      false
    end

    # Returns `true`.
    #
    # @example
    #   x = T.let(R.err("Some error message"), R::Result[Integer, String])
    #   x.err? # => true
    #
    # @see R::Ok#err?
    # @see R::Err#err?
    sig(:final) { override.returns(TrueClass) }
    def err?
      true
    end

    # Returns `true` if the value matches a predicate.
    #
    # @example
    #   x = T.let(R.err(ArgumentError.new), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => true
    #
    #   x = T.let(R.err(IOError.new), R::Result[Integer, StandardError])
    #   x.err_and? { |x| x.is_a?(ArgumentError) } # => false
    #
    # @see R::Result#err_and?
    # @see R::Ok#err_and?
    sig(:final) { override.params(blk: T.proc.params(value: ErrType).returns(T::Boolean)).returns(T::Boolean) }
    def err_and?(&blk)
      yield(@value)
    end

    # Returns `nil`.
    #
    # @example
    #   x = T.let(R.err("Nothing here"), R::Result[Integer, String])
    #   x.ok => nil
    #
    # @see R::Result#ok
    # @see R::Ok#ok
    sig(:final) { override.returns(NilClass) }
    def ok
      nil
    end

    # Returns the value.
    #
    # @example
    #   x = T.let(R.err("Nothing here"), R::Result[Integer, String])
    #   x.err => "Nothing here"
    #
    # @see R::Result#err
    # @see R::Ok#err
    sig(:final) { override.returns(ErrType) }
    def err
      @value
    end

    # Returns `self`.
    #
    # This function can be used to compose the results of two functions.
    #
    # @see R::Result#map
    # @see R::Ok#map
    sig(:final) do
      override
        .type_parameters(:U)
        .params(blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)))
        .returns(Err[ErrType])
    end
    def map(&blk)
      self
    end

    # Returns the provided default.
    #
    # Arguments passed to {#map_or} are eagerly evaluated; if you are passing the result of a function call, it is
    # recommended to use {#map_or_else}, which is lazily evaluated.
    #
    # @example
    #   x = T.let(R.err("bar"), R::Result[String, String])
    #   x.map_or(42) { |v| v.size } # => 42
    #
    # @see R::Result#map_or
    # @see R::Ok#map_or
    sig(:final) do
      override
        .type_parameters(:U)
        .params(
          default: T.type_parameter(:U),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or(default, &blk)
      default
    end

    # Maps a {Result}`[T, E]` to `U` by applying fallback function `default` to the contained {Err} value.
    #
    # This function can be used to unpack a successful result while handling an error.
    #
    # @example
    #   k = 21
    #
    #   x = T.let(R.err("bar"), R::Result[Integer, String])
    #   x.map_or_else(->(e) { k * 2 }) { |v| v.size } # => 42
    #
    # @see R::Result#map_or_else
    # @see R::Ok#map_or_else
    sig(:final) do
      override
        .type_parameters(:U)
        .params(
          default: T.proc.params(value: ErrType).returns(T.type_parameter(:U)),
          blk: T.proc.params(value: OkType).returns(T.type_parameter(:U)),
        )
        .returns(T.type_parameter(:U))
    end
    def map_or_else(default, &blk)
      default.call(@value)
    end

    # Maps a {Result}`[T, E]` to {Result}`[T, F]` by applying a function to the contained {Err} value.
    #
    # @see R::Result#map_err
    sig(:final) do
      override
        .type_parameters(:F)
        .params(blk: T.proc.params(value: ErrType).returns(T.type_parameter(:F)))
        .returns(Err[T.type_parameter(:F)])
    end
    def map_err(&blk)
      Err.new(yield(@value))
    end

    # sig { override.params(blk: T.proc.params(arg: T).returns(T.untyped)).returns(T.self_type) }
    # def each(&blk)
    #   self
    # end

    # Raises an {UnwrapFailedError} exception.
    #
    # @see R::Result#expect!
    sig(:final) { override.params(msg: String).returns(T.noreturn) }
    def expect!(msg)
      raise UnwrapFailedError.new(msg, @value)
    end

    # Raises an {UnwrapFailedError} exception.
    #
    # @see R::Result#unwrap!
    sig(:final) { override.returns(T.noreturn) }
    def unwrap!
      raise UnwrapFailedError.new("called `Result#unwrap!` on an `Err` value", @value)
    end

    # Returns the contained {Err} value.
    #
    # @see R::Result#expect_err!
    sig(:final) { override.params(msg: String).returns(ErrType) }
    def expect_err!(msg)
      @value
    end

    # Returns the contained {Err} value.
    #
    # @see R::Result#unwrap_err!
    sig(:final) { override.returns(ErrType) }
    def unwrap_err!
      @value
    end

    # Returns the {Err} value of `self`.
    #
    # @see R::Result#and
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[T.type_parameter(:U), ErrType])
    end
    def and(res)
      self
    end

    # returns the {Err} value of `self`.
    #
    # @see R::Result#and_then
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: OkType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[T.type_parameter(:U), ErrType])
    end
    def and_then(&blk)
      self
    end

    # Returns `res`.
    #
    # @see R::Result#or
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(res: Result[T.type_parameter(:U), T.type_parameter(:F)])
        .returns(Result[T.type_parameter(:U), T.type_parameter(:F)])
    end
    def or(res)
      res
    end

    # Calls the block.
    #
    # @see R::Result#or_else
    sig(:final) do
      override
        .type_parameters(:U, :F)
        .params(blk: T.proc.params(arg: ErrType).returns(Result[T.type_parameter(:U), T.type_parameter(:F)]))
        .returns(Result[T.type_parameter(:U), T.type_parameter(:F)])
    end
    def or_else(&blk)
      yield(@value)
    end

    # Returns the provided default.
    #
    # @see R::Result#unwrap_or
    sig(:final) do
      override
        .type_parameters(:DefaultType)
        .params(default: T.type_parameter(:DefaultType))
        .returns(T.type_parameter(:DefaultType))
    end
    def unwrap_or(default)
      default
    end

    # Computes an {Ok} value from a closure.
    #
    # @see R::Result#unwrap_or_else
    sig(:final) do
      override
        .type_parameters(:DefaultType)
        .params(blk: T.proc.params(arg: ErrType).returns(T.type_parameter(:DefaultType)))
        .returns(T.type_parameter(:DefaultType))
    end
    def unwrap_or_else(&blk)
      yield(@value)
    end

    # Computes an {Ok} value from a closure.
    #
    # @see R::Result#unwrap_or_else
    sig(:final) do
      override
        .params(blk: T.proc.params(arg: Err[ErrType]).returns(T.noreturn))
        .returns(T.noreturn)
    end
    def try?(&blk)
      yield(self)
    end

    #
    # CALLBACK API -- not part of Rust
    #

    sig(:final) { override.params(blk: T.proc.params(value: OkType).void).returns(T.self_type) }
    def on_ok(&blk)
      self
    end

    sig(:final) { override.params(blk: T.proc.params(value: ErrType).void).returns(T.self_type) }
    def on_err(&blk)
      yield(@value)
      self
    end
  end
end
