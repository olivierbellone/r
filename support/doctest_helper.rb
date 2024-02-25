# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

require "r"

extend T::Sig

sig { params(x: Integer).returns(String) }
def stringify(x)
  "error code: #{x}"
end

sig { params(x: Integer).returns(R::Result[String, String]) }
def sqrt_then_to_s(x)
  return R::Err("negative value") if x < 0

  R::Ok(Math.sqrt(x).to_s)
end

sig { params(x: Integer).returns(R::Result[Integer, Integer]) }
def sq(x)
  R::Ok(x * x)
end

sig { params(x: Integer).returns(R::Result[Integer, Integer]) }
def err_(x)
  R::Err(x)
end

sig { params(str: String).returns(R::Result[Integer, String]) }
def parse_int(str)
  R::Ok(Integer(str))
rescue ArgumentError
  R::Err("Cannot parse #{str} as an integer")
end
