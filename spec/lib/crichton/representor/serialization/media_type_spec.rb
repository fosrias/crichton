require 'spec_helper'
require 'crichton/representor/serializer'
require 'crichton/representor/serialization/media_type'

module Crichton
  module Representor
    module Serialization
      describe MediaType do
        let (:simple_test_instance) do
          klass = Class.new do
            include MediaType
          end
          klass.new
        end
        
        before do
          @options = double('options')
          @serializer = double('serializer')
          stub_factory_method = allow(Crichton::Representor::Serializer).to receive(:build)
          stub_factory_method.with(:media_type, simple_test_instance, @options).and_return(@serializer)
        end
        
        describe '#as_media_type' do
          it 'delegates to a built serializer for the media type' do
            expect(@serializer).to receive(:as_media_type).with(@options)
            simple_test_instance.as_media_type(:media_type, @options)
          end
        end

        describe '#to_media_type' do
          it 'delegates to a built serializer for the media type' do
            expect(@serializer).to receive(:to_media_type).with(@options)
            simple_test_instance.to_media_type(:media_type, @options)
          end
        end
      end
    end
  end
end
