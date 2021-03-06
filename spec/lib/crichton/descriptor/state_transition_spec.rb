require 'spec_helper'
require 'crichton/descriptor/state_transition'

module Crichton
  module Descriptor
    describe StateTransition do
      let(:state_transitions) { normalized_drds_descriptor['descriptors']['drds']['states']['collection']['transitions'] }
      let(:state_transition_descriptor) { state_transitions['create'] }
      let(:resource_descriptor) { double('resource_descriptor') }
      let(:descriptor) { StateTransition.new(resource_descriptor, state_transition_descriptor) }
      
      describe '#available?' do
        context 'without :conditions option' do
          it 'always returns true' do
            state_transition_descriptor.delete('conditions')
            expect(descriptor).to be_available
          end
        end
        
        context 'with :conditions option' do
          context 'with a string for a state transition condition' do
            it 'returns true with a matching string option' do
              expect(descriptor).to be_available({conditions: 'can_create'})
            end
  
            it 'returns true with a matching symbol option' do
              expect(descriptor).to be_available({conditions: :can_create})
            end
  
            it 'returns false without a matching string option' do
              expect(descriptor).not_to be_available({conditions: 'can_do_something'})
            end
  
            it 'returns false without a matching symbol option' do
              expect(descriptor).not_to be_available({conditions: :can_do_something})
            end
          end
          
          context 'with a hash for a state transition condition' do
            before do
              state_transition_descriptor['conditions'] = [{'can_create' => 'object'}]
            end

            it 'returns true with a matching hash option' do
              expect(descriptor).to be_available({conditions: {can_create: :object}})
            end

            it 'returns false without a matching hash option' do
              expect(descriptor).not_to be_available({conditions: {can_create: 'other_object'}})
            end

            it 'returns false with any string option' do
              expect(descriptor).not_to be_available({conditions: 'can_create'})
            end

            it 'returns false with any symbol option' do
              expect(descriptor).not_to be_available({conditions: :can_create})
            end
          end
        end
      end
  
      describe '#conditions' do
        it 'returns the list of inclusion conditions for the transition' do
          expect(descriptor.conditions).to eq(%w(can_create can_do_anything))
        end
        
        it 'returns an empty hash when there are no conditions specified' do
          state_transition_descriptor.delete('conditions')
          expect(descriptor.conditions).to be_empty
        end
      end
  
      describe '#next' do
        it 'returns the list of next states exposed by the transition' do
          expect(descriptor.next).to eq(%w(activated error))
        end

        it 'returns an empty hash when there are no next states specified' do
          state_transition_descriptor.delete('next')
          expect(descriptor.next).to be_empty
        end
      end
    end
  end
end
