require 'crichton/representor/serializer'
require "json"

module Crichton
  module Representor

    ##
    # Manages the serialization of a Crichton::Representor to an application/vnd.hale+json media-type.
    class HaleJsonSerializer < Serializer
      media_types hale_json: %w(application/vnd.hale+json)

      DATA = 'data'

      #maps descriptor datatypes to simple datatypes
      SEMANTIC_TYPES = {
        select: "text", #No way in Crichton to distinguish [Int] and [String]
        search:"text",
        text: "text",
        boolean: "bool", #a Server should accept ?cat&dog or ?cat=cat&dog=dog
        number: "number",
        email: "text",
        tel: "text",
        datetime: "text",
        time: "text",
        date: "text",
        month: "text",
        week: "text",
        object: "object",
        :"datetime-local" => "text"
      }
      ##
      # Returns a ruby object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def as_media_type(options = {})
        options ||= {}
        halelets = []
        halelets << get_semantic_data(options)
        halelets << get_data(@object.each_transition(options), relations)
        halelets << get_data(@object.metadata_links(options), relations)
        base_object = halelets.reduce(&:deep_merge)
        add_embedded(base_object, options)
      end

      ##
      # Returns a json object representing a HALe serialization.
      #
      # @param [Hash] options Optional configurations.
      #
      # @return [Hash] The built representation.
      def to_media_type(options)
        as_media_type(options).to_json
      end

      private

      def deep_merge(x, y)
        x.deep_merge(y)
      end

      def semantic_map(sem)
        {type: "#{SEMANTIC_TYPES[sem.to_sym]}:#{sem}"}
      end

      def hale_links(transition_name, transition_semantic, data)
        { _links: { transition_name => { DATA => { transition_semantic.name => data } } } }
      end
      
      def hale_meta_options(transition_semantic)
        hale_meta_opts = if transition_semantic.semantics.any?
          transition_semantic.semantics.values.map { |value| hale_meta_options(value) }.reduce(&:deep_merge)
        end
        options = transition_semantic.options
        external = if options && options.external?
          { "#{transition_semantic.name}_options" =>  { _source: options.source, _target: options.target || "." } }
        end
        (hale_meta_opts || {}).deep_merge(external || {})
      end
      
      def get_options(transition_semantic)
        options = transition_semantic.options
        if options.external?
          { "#{transition_semantic.name}_options.options" => {} }
        elsif options.enumerable?
          { :options => options.each { |k, v| {k => v} } }
        else
          {}
        end
      end

      def get_control(transition_semantic)
        halelet_semantics = traverse_and_merge(transition_semantic.semantics, method(:get_control))
        halelet = build_halelet(transition_semantic)
        halelet_semantics.any? ? halelet.merge(DATA => halelet_semantics) : halelet
      end

      def build_halelet(semantic_element)
        type_data = semantic_map(semantic_element.field_type || 'object')
        scope_url = semantic_element.scope? ? type_data.merge({ 'scope' => 'href' }) : type_data
        multi = semantic_element.multiple? ? scope_url.merge({ 'multi' => 'true' }) : scope_url
        validators = multi.merge(handle_validator(semantic_element.validators))
        halelet_opt = get_options(semantic_element)
        validators.deep_merge(halelet_opt)
      end

      def relations
        ->(transition) { get_form_transition(transition) }
      end

      def get_link_transition(transition)
        link = { href: transition.url }
        link = { href: transition.templated_url, templated: true } if transition.templated? && transition.name != 'self'
        method = defined?(transition.interface_method) ? transition.interface_method : 'GET'
        link = link.merge({ method: method }) unless method == 'GET'
        link[:href] ? { _links: { transition.name => link } } : {}
      end
      
      def handle_validator(validators)
        validators["required"] = true if validators.has_key?("required")
        validators
      end
      
      def get_form_transition(transition)
        form_elements = get_form_elements(transition)
        link = get_link_transition(transition)
        link.deep_merge(form_elements)
      end

      def get_form_elements(transition)
        if transition.name == 'self'
          return {}
        end
        semantics = defined?(transition.semantics) ? transition.semantics : {}
        semantics.values.each_with_object({}) do |semantic, h|
          halelet = get_control(semantic)
          hale_options = { _meta: hale_meta_options(semantic) }
          hale_document = hale_links(transition.name, semantic, halelet).merge(hale_options)
          h.deep_merge!(hale_document)
        end
      end

      def get_semantic_data(options)
        semantic_data = @object.each_data_semantic(options)
        each_pair = ->(descriptor) { { descriptor.name => descriptor.value } }
        get_data(semantic_data, each_pair)
      end

      def get_data(semantic_element, transformation)
        Hash[semantic_element.map(&transformation).reduce({}, &:deep_merge)]
      end

      def add_embedded(base_object, options)
        if (embedded = get_embedded(options)) && embedded.any?
          base_object[:_embedded] = embedded
          add_embedded_links(base_object, embedded)
        end
        base_object
      end

      def add_embedded_links(base_object, embedded)
        embedded_links = embedded.reduce({}) { |h, (k, v)| h[k] = get_base_links(v); h }
        base_object[:_links] = base_object[:_links].merge(embedded_links)
      end

      def get_embedded(options)
        @object.each_embedded_semantic(options).inject({}) do |hash, semantic|
          hash[semantic.name] = get_embedded_elements(semantic, options) ; hash
        end
      end

      def get_base_links(hale_obj)
        hale_obj.map { |item| { href: item[:_links]['self'][:href], type: item[:_links]['type'][:href] } }
      end

      #Todo: Move to a helpers.rb file
      def map_or_apply(unknown_object, function)
        unknown_object.is_a?(Array) ? unknown_object.map(&function) : function.(unknown_object)
      end

      def traverse_and_merge(object, function)
        object.any? ? object.map { |name, child| { name => function.(child) } }.reduce(&:deep_merge) : {}
      end

      #Todo: Make Representor::xhtml refactored similarly
      def get_embedded_elements(semantic, options)
        map_or_apply(semantic.value, ->(object) { get_embedded_hale(object, options) })
      end

      def get_embedded_hale(object, options)
        object.as_media_type(self.class.default_media_type, options)
      end
    end
  end
end
