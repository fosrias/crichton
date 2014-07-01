require 'spec_helper'

describe Crichton::Discovery::EntryPoints do

  let(:resource_uri) { "foos" }
  let(:resource_relation) {"foos"}
  let(:transition_id) {"list"}
  let(:resource_id) {"Foo"}

  let(:entry_point) do
    Crichton::Discovery::EntryPoint.new(resource_uri, resource_relation, resource_id)
  end

  let(:instance) {described_class.new([entry_point])}

  it "is a kind of Crichton::Representor" do
    expect(instance).to be_kind_of Crichton::Representor
  end

  shared_examples_for "a jsony-producer" do |media_type_s, media_type_sym|

    describe media_type_s do

      let(:expected_hale_json) do
        <<JSON
    {"_links":
       {
        "#{entry_point.link_relation}":
         {
          "href": "#{entry_point.href}",
          "name": "#{entry_point.name}"
         }
       }
    }
JSON
      end

      describe "#as_media_type" do
        it "produces :#{media_type_sym} format" do
          result = instance.as_media_type(media_type_sym, {})
          expect(result).to be_json_eql(expected_hale_json)
        end
      end

      describe "#to_media_type" do
        it "produces :#{media_type_sym} format" do
          result = instance.to_media_type(media_type_sym)
          expect(result).to be_json_eql(expected_hale_json)
        end
      end
    end
  end

  it_behaves_like 'a jsony-producer', 'application/json', :json
  it_behaves_like 'a jsony-producer', 'application/vnd.hale+json', :hale_json
  it_behaves_like 'a jsony-producer', 'application/vnd.hal+json', :hal_json

  describe "text/html and application/xhtml" do

    let(:expected_markup) do
      <<MARKUP.gsub /^\s+/, ""
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head/>
 <body>
   <div itemscope="itemscope">
     <a rel="#{entry_point.link_relation}" href="#{entry_point.href}">#{entry_point.name}</a>
   </div>
  </body>
</html>
MARKUP
    end

    describe "as_media_type" do
      it "produces html" do
        #NOTE rails use the :html sym for both :html, and :xhtml
        result = instance.as_media_type(:html, {})
        expect(result).to eq expected_markup
      end
    end

    describe "to_media_type" do
      it "produces html" do
        result = instance.to_media_type(:html)
        expect(result).to eq expected_markup
      end
    end
  end
end
