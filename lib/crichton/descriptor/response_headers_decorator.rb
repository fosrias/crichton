module Crichton
  module Descriptor
    class ResponseHeadersDecorator
      EXTERNAL = 'external'
      SOURCE = 'source'

      attr_reader :descriptor

      def initialize(descriptor, target)
        @descriptor = descriptor || {}
        @target = target
      end

      def to_hash
        @header ||= if external = descriptor[EXTERNAL]
          source = external[SOURCE]
          @target.respond_to?(source) ? respond_to_method(source) : {}
        else
          descriptor
        end
      end

      private
      def respond_to_method(method)
        @target.send(method).tap do |result|
          raise_if_invalid(!result.is_a?(Hash), throw("#{method} method on target must return Hash object"))
        end
      end

      def raise_if_invalid(condition, throw_function)
        throw_function.call if condition
      end

      def throw(message = '')
        ->(){ raise Crichton::TargetMethodResponseError, message }
      end
    end
  end
end
