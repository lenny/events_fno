require 'spec_helper'

require 'events_fno/support/command_executor'
require 'ostruct'
require 'events_fno/contracts'

module EventsFno
  module Support
    RSpec.describe CommandExecutor do
      class MyCommand
        include Contracts::Command
      end

      def new_command
        MyCommand.new.tap do |cmd|
          allow(cmd).to receive(:execute)
          allow(cmd).to receive(:valid?).and_return(true)
        end
      end

      class MyCommandFactory
        include Contracts::CommandFactory
      end

      let(:command_factory) do
        MyCommandFactory.new.tap do |factory|
          allow(factory).to receive(:new_command) do
            new_command
          end
        end
      end

      let(:events_committer) { double('EventCommitter', commit_events: nil) }

      subject do
        CommandExecutor.new(command_factory: command_factory, events_committer: events_committer)
      end

      it 'instantiates command instance via command factory' do
        expect(command_factory).to receive(:new_command).with('some/command', foo: 'FOO')
        subject.execute(double('Aggregate'), name: 'some/command', data: { foo: 'FOO' })
      end

      it 'executes instantiated command and returns committed event records' do
        aggregate = double('Aggregate')
        command = new_command
        event_record = double('EventRecord')
        expect(command).to receive(:execute).with(aggregate, anything)
                               .and_return([event_record])
        expect(command_factory).to receive(:new_command).and_return(command)
        expect(events_committer).to receive(:commit_events).with([event_record])
        expect(subject.execute(aggregate, name: 'some/command', data: { foo: 'FOO' })).to eq([event_record])
      end

      it 'validates command and raises error when invalid' do
        command = new_command
        expect(command).to receive(:valid?).and_return(false)
        expect(command_factory).to receive(:new_command).and_return(command)
        expect {
          subject.execute(double('Aggregate'), name: 'some/command')
        }.to raise_error /invalid/
      end
    end
  end
end