# typed: strict
# frozen_string_literal: true

require "test_helper"

module R
  class ResultTest < Minitest::Test
    describe "R.ok" do
      it "returns a new instance of R::Ok" do
        x = R.ok(0)

        assert_instance_of(R::Ok, x)
      end
    end

    describe "R.err" do
      it "returns a new instance of R::Err" do
        x = R.err("hey")

        assert_instance_of(R::Err, x)
      end
    end

    describe Result do
      describe "#==" do
        it "returns true if self and other are both Ok and the value is the same" do
          x = T.let(R.ok(2), R::Result[Integer, Integer])

          assert_equal(true, x == R.ok(2))
          assert_equal(false, x == R.ok(3))
          assert_equal(false, x == R.err(2))
          assert_equal(false, x == "not a Result")
        end

        it "returns true if self and other are both Err and the value is the same" do
          x = T.let(R.err(2), R::Result[Integer, Integer])

          assert_equal(true, x == R.err(2))
          assert_equal(false, x == R.err(3))
          assert_equal(false, x == R.ok(2))
          assert_equal(false, x == "not a Result")
        end
      end

      describe "#inspect" do
        it "prints the class name and the value's inspect representation" do
          assert_equal("R.ok(2)", R.ok(2).inspect)
          assert_equal("R.err(\"error\")", R.err("error").inspect)
        end

        it "handles uninspectable values" do
          assert_equal("R.ok(<uninspectable value>)", R.ok(BasicObject.new).inspect)
          assert_equal("R.err(<uninspectable value>)", R.err(BasicObject.new).inspect)
        end
      end

      describe "#ok?" do
        it "returns true if the result is Ok" do
          x = T.let(R.ok(-3), R::Result[Integer, String])

          assert_equal(true, x.ok?)
        end

        it "returns false if the result is Err" do
          x = T.let(R.err("Some error message"), R::Result[Integer, String])

          assert_equal(false, x.ok?)
        end
      end

      describe "#ok_and?" do
        it "returns true if the result is Ok and the value inside of it matches a predicate" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(true, x.ok_and? { |x| x > 1 })

          x = T.let(R.ok(0), R::Result[Integer, String])

          assert_equal(false, x.ok_and? { |x| x > 1 })
        end

        it "returns false if the result is Err" do
          x = T.let(R.err("hey"), R::Result[Integer, String])

          assert_equal(false, x.ok_and? { |x| x > 1 })
        end
      end

      describe "#err?" do
        it "returns false if the result is Ok" do
          x = T.let(R.ok(-3), R::Result[Integer, String])

          assert_equal(false, x.err?)
        end

        it "returns true if the result is Err" do
          x = T.let(R.err("Some error message"), R::Result[Integer, String])

          assert_equal(true, x.err?)
        end
      end

      describe "#err_and?" do
        it "Returns true if the result is Err and the value inside of it matches a predicate" do
          x = T.let(R.err(ArgumentError.new), R::Result[Integer, StandardError])

          assert_equal(true, x.err_and? { |x| x.is_a?(ArgumentError) })

          x = T.let(R.err(IOError.new), R::Result[Integer, StandardError])

          assert_equal(false, x.err_and? { |x| x.is_a?(ArgumentError) })
        end

        it "returns false if the result is Ok" do
          x = T.let(R.ok(123), R::Result[Integer, StandardError])

          assert_equal(false, x.err_and? { |x| x.is_a?(ArgumentError) })
        end
      end

      describe "#ok" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(2, x.ok)
        end

        it "returns nil if the result is Err" do
          x = T.let(R.err("Nothing here"), R::Result[Integer, String])

          assert_nil(x.ok)
        end
      end

      describe "#err" do
        it "returns nil if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_nil(x.err)
        end

        it "returns the value if the result is Err" do
          x = T.let(R.err("Nothing here"), R::Result[Integer, String])

          assert_equal("Nothing here", x.err)
        end
      end

      describe "#map" do
        it "applies a function if the result is Ok" do
          x = T.let(R.ok("2"), R::Result[String, String])

          assert_equal(R.ok(4), x.map { |i| Integer(i) * 2 })
        end

        it "leaves the value untouched if the result is Err" do
          x = T.let(R.err("not an integer"), R::Result[String, String])

          assert_equal(x, x.map { |i| Integer(i) * 2 })
        end
      end

      describe "#map_or" do
        it "applies a function if the result is Ok" do
          x = T.let(R.ok("foo"), R::Result[String, String])

          assert_equal(3, x.map_or(42, &:size))
        end

        it "returns the provided default if the result is Err" do
          x = T.let(R.err("bar"), R::Result[String, String])

          assert_equal(42, x.map_or(42, &:size))
        end
      end

      describe "#map_or_else" do
        before do
          k = 21
          @default = T.let(
            ->(_e) { k * 2 },
            T.proc.params(e: String).returns(Integer),
          )
        end

        it "applies a function if the result is Ok" do
          x = T.let(R.ok("foo"), R::Result[String, String])

          assert_equal(3, x.map_or_else(@default, &:size))
        end

        it "applies fallback function default if the result is Err" do
          x = T.let(R.err("bar"), R::Result[Integer, String])

          assert_equal(42, x.map_or_else(@default, &:size))
        end
      end

      describe "#map_err" do
        before do
          @stringify = T.let(
            ->(x) { "error code: #{x}" },
            T.proc.params(x: Integer).returns(String),
          )
        end

        it "returns the untouched result if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, Integer])

          assert_equal(x, x.map_err { |x| @stringify.call(x) })
        end

        it "applies a function if the result is Err" do
          x = T.let(R.err(13), R::Result[Integer, Integer])

          assert_equal(R.err("error code: 13"), x.map_err { |x| @stringify.call(x) })
        end
      end

      describe "#on_ok" do
        it "calls the block if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, Integer])
          msg = T.let(nil, T.nilable(String))

          x.on_ok { |x| msg = "Success: #{x}" }

          assert_equal("Success: 2", msg)
        end

        it "does nothing if the result is Err" do
          x = T.let(R.err(3), R::Result[Integer, Integer])
          msg = T.let(nil, T.nilable(String))

          x.on_ok { |x| msg = "Success: #{x}" }

          assert_nil(msg)
        end
      end

      describe "#on_err" do
        it "does nothing if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, Integer])
          msg = T.let(nil, T.nilable(String))

          x.on_err { |x| msg = "Failure: #{x}" }

          assert_nil(msg)
        end

        it "calls the block if the result is Err" do
          x = T.let(R.err(3), R::Result[Integer, Integer])
          msg = T.let(nil, T.nilable(String))

          x.on_err { |x| msg = "Failure: #{x}" }

          assert_equal("Failure: 3", msg)
        end
      end

      describe "#expect!" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(2, x.expect!("Testing expect"))
        end

        it "raises an UnwrapFailedError exception if the result is Err" do
          x = T.let(R.err("emergency failure"), R::Result[Integer, String])

          e = assert_raises(UnwrapFailedError) do
            x.expect!("Testing expect!")
          end
          assert_equal("Testing expect!: \"emergency failure\"", e.message)
        end
      end

      describe "#unwrap!" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(2, x.unwrap!)
        end

        it "raises an UnwrapFailedError exception if the result is Err" do
          x = T.let(R.err("emergency failure"), R::Result[Integer, String])

          e = assert_raises(UnwrapFailedError) do
            x.unwrap!
          end
          assert_equal("called `Result#unwrap!` on an `Err` value: \"emergency failure\"", e.message)
        end
      end

      describe "#expect_err!" do
        it "raises an UnwrapFailedError exception if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          e = assert_raises(UnwrapFailedError) do
            x.expect_err!("Testing expect_err!")
          end
          assert_equal("Testing expect_err!: 2", e.message)
        end

        it "returns the value if the result is Err" do
          x = T.let(R.err("emergency failure"), R::Result[Integer, String])

          assert_equal("emergency failure", x.expect_err!("Testing expect_err!"))
        end
      end

      describe "#unwrap_err!" do
        it "raises an UnwrapFailedError exception if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          e = assert_raises(UnwrapFailedError) do
            x.unwrap_err!
          end
          assert_equal("called `Result#unwrap_err!` on an `Ok` value: 2", e.message)
        end

        it "returns the value if the result is Err" do
          x = T.let(R.err("emergency failure"), R::Result[Integer, String])

          assert_equal("emergency failure", x.unwrap_err!)
        end
      end

      describe "#and" do
        it "returns the passed result if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])
          y = T.let(R.ok("different result type"), R::Result[String, String])

          assert_equal(y, x.and(y))

          x = T.let(R.ok(2), R::Result[Integer, String])
          y = T.let(R.err("late error"), R::Result[String, String])

          assert_equal(y, x.and(y))
        end

        it "returns self if the result is Err" do
          x = T.let(R.err("early error"), R::Result[Integer, String])
          y = T.let(R.ok("foo"), R::Result[String, String])

          assert_equal(x, x.and(y))

          x = T.let(R.err("not a 2"), R::Result[Integer, String])
          y = T.let(R.err("late error"), R::Result[String, String])

          assert_equal(x, x.and(y))
        end
      end

      describe "#and_then" do
        before do
          @sq_then_to_s = T.let(
            ->(x) { (-1_000..1_000).cover?(x) ? R.ok((x**2).to_s) : R.err("overflowed") },
            T.proc.params(x: Integer).returns(R::Result[String, String]),
          )
        end

        it "calls the block if the result is Ok" do
          assert_equal(R.ok(4.to_s), R.ok(2).and_then { |x| @sq_then_to_s.call(x) })
          assert_equal(R.err("overflowed"), R.ok(1_000_000).and_then { |x| @sq_then_to_s.call(x) })
        end

        it "returns self for Err" do
          x = T.let(R.err("not a number"), R::Result[Integer, String])

          assert_equal(x, x.and_then { |x| @sq_then_to_s.call(x) })
        end
      end

      describe "#or" do
        it "returns self if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])
          y = T.let(R.err("late error"), R::Result[Integer, String])

          assert_equal(x, x.or(y))

          x = T.let(R.ok(2), R::Result[Integer, String])
          y = T.let(R.ok(100), R::Result[Integer, String])

          assert_equal(x, x.or(y))
        end

        it "returns the passed result if the result is Err" do
          x = T.let(R.err("early error"), R::Result[Integer, String])
          y = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(y, x.or(y))

          x = T.let(R.err("not a 2"), R::Result[Integer, String])
          y = T.let(R.err("late error"), R::Result[String, String])

          assert_equal(y, x.or(y))
        end
      end

      describe "#or_else" do
        before do
          @sq = T.let(
            ->(x) { R.ok(x**2) },
            T.proc.params(x: Integer).returns(R::Result[Integer, Integer]),
          )
          @err = T.let(
            ->(x) { R.err(x) },
            T.proc.params(x: Integer).returns(R::Result[Integer, Integer]),
          )
        end

        it "returns self if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, Integer])

          assert_equal(R.ok(2), x.or_else { |x| @sq.call(x) }.or_else { |x| @sq.call(x) })
          assert_equal(R.ok(2), x.or_else { |x| @err.call(x) }.or_else { |x| @sq.call(x) })
        end

        it "calls the block if the result is Err" do
          x = T.let(R.err(3), R::Result[Integer, Integer])

          assert_equal(R.ok(9), x.or_else { |x| @sq.call(x) }.or_else { |x| @err.call(x) })
          assert_equal(R.err(3), x.or_else { |x| @err.call(x) }.or_else { |x| @err.call(x) })
        end
      end

      describe "#unwrap_or" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(9), R::Result[Integer, String])

          assert_equal(9, x.unwrap_or(2))
        end

        it "returns the provided default if the result is Err" do
          x = T.let(R.err("error"), R::Result[Integer, String])

          assert_equal(2, x.unwrap_or(2))
        end
      end

      describe "#unwrap_or_else" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(2, x.unwrap_or_else(&:size))
        end

        it "computes the value from a closure if the result is Err" do
          x = T.let(R.err("foo"), R::Result[Integer, String])

          assert_equal(3, x.unwrap_or_else(&:size))
        end
      end

      describe "#try?" do
        it "returns the value if the result is Ok" do
          x = T.let(R.ok(2), R::Result[Integer, String])

          assert_equal(2, x.try? { |e| raise "Error: #{e.err}" })
        end

        it "computes the value from a closure if the result is Err" do
          x = T.let(R.err("foo"), R::Result[Integer, String])

          e = assert_raises(RuntimeError) do
            x.try? { |e| raise "Error: #{e.err}" }
          end
          assert_equal("Error: foo", e.message)
        end
      end
    end
  end
end
