# typed: strict
# frozen_string_literal: true

module R
  # {UnwrapFailedError} is raised by {R::Result#unwrap!} and {R::Result#unwrap_err!} (and their
  # variants  {R::Result#expect!} and {R::Result#expect_err!}) when called on the wrong result
  # type.
  #
  # @see R::Result#unwrap!
  # @see R::Result#unwrap_err!
  # @see R::Result#expect!
  # @see R::Result#expect_err!
  class UnwrapFailedError < StandardError
    extend ::T::Sig

    sig { returns(T.anything) }
    attr_reader :value

    sig { params(message: String, value: T.anything).void }
    def initialize(message, value)
      super(format_message(message, value))
      @value = value
    end

    private

    sig { params(message: String, value: T.anything).returns(String) }
    def format_message(message, value)
      value_repr = case value
      when Kernel
        value.inspect
      else
        "<uninspectable value>"
      end

      "#{message}: #{value_repr}"
    end
  end
end
