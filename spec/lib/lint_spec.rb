require 'spec_helper'
require 'lint'

describe Lint do
  before do
    Crichton.clear_registry
    Crichton.clear_config
  end

  it "displays a success statement when linting a clean resource descriptor file" do
    content = capture(:stdout) { Lint.validate(drds_filename) }
    content.should == "#{I18n.t('aok')}\n"
  end

  it "display a missing states section error when the states section is missing" do
    filename = lint_spec_filename('missing_sections', 'nostate_descriptor.yml')
    content = capture(:stdout) { Lint.validate(filename) }
    error = expected_output(:error, 'catastrophic.section_missing', section: 'states', filename: filename)
    content.should == error
  end

  it "display missing descriptor errors when the descriptor section is missing" do
    filename = lint_spec_filename('missing_sections', 'nodescriptors_descriptor.yml')

    errors = expected_output(:error, 'catastrophic.section_missing',
      section: 'descriptors', filename: filename) <<
      expected_output(:error, 'catastrophic.no_secondary_descriptors')

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "display a missing protocols section error when the protocols section is missing" do
    filename = lint_spec_filename('missing_sections', 'noprotocols_descriptor.yml')
    content = capture(:stdout) { Lint.validate(filename) }
    error = expected_output(:error, 'catastrophic.section_missing', section: 'protocols', filename: filename)
    content.should == error
  end

  it "display warnings correlating to self: and doc: issues when they are found in a descriptor file" do
    filename = lint_spec_filename('state_section_errors', 'condition_doc_and_self_errors.yml')

    warnings = expected_output(:warning, 'states.no_self_property', resource: 'drds',
      state: 'collection', transition: 'list',  filename: filename) <<
      expected_output(:warning, 'states.doc_property_missing', resource: 'drd', state: 'activated',
      filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == warnings
  end

  it "display errors when next transitions are missing or empty" do
    filename = lint_spec_filename('state_section_errors', 'missing_and_empty_transitions.yml')

    errors = expected_output(:error, 'states.empty_missing_next', resource: 'drds',
      state: 'collection', transition: 'list',  filename: filename) <<
      expected_output(:error, 'states.empty_missing_next', resource: 'drd',
      state: 'activated', transition: 'show',  filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end

  it "display errors when next transitions are pointing to non-existent states" do
    filename = lint_spec_filename('state_section_errors', 'phantom_transitions.yml')

    errors = expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drds',
      state: 'navigation', transition: 'self', next_state: 'navegation',  filename: filename) <<
      expected_output(:error, 'states.phantom_next_property', secondary_descriptor: 'drd',
      state: 'activated', transition: 'self', next_state: 'activate',  filename: filename)

    content = capture(:stdout) { Lint.validate(filename) }
    content.should == errors
  end
end