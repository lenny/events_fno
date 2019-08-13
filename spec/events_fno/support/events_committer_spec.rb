require 'spec_helper'

require 'events_fno/support/events_committer'
require 'ostruct'
require 'events_fno/contracts'

module EventsFno
  module Support
    RSpec.describe EventsCommitter do
      def new_event_record(aggregate, values = {})
        OpenStruct.new({ aggregate: aggregate, name: 'some/event', data: nil }.merge(values))
      end

      class MyEventFactory
        include Contracts::EventFactory
      end

      let(:event_factory) do
        MyEventFactory.new.tap do |f|
          allow(f).to receive(:new_event) do |name, data|
            double('Event', apply: true)
          end
        end
      end

      let(:transaction_svc) do
        double('TransactionSvc').tap do |s|
          allow(s).to receive(:transaction).and_yield
        end
      end

      let(:aggregate_repository) { double('AggregateRepository', save!: true) }

      let(:event_record_repository) do
        double('EventRecordRepository', save!: true).tap do |double|
          allow(double).to receive(:prepare_data) do |event_record|
            event_record
          end
        end
      end

      subject do
        EventsCommitter.new(event_factory: event_factory,
                            transaction_svc: transaction_svc,
                            aggregate_repository: aggregate_repository,
                            event_record_repository: event_record_repository)
      end

      it 'applies each event' do
        aggregate = double('Aggregate)')
        e1 = new_event_record(aggregate)
        e2 = new_event_record(aggregate)
        expect(subject).to receive(:apply_event).with(e1)
        expect(subject).to receive(:apply_event).with(e2)
        subject.commit_events([e1, e2])
      end

      it 'saves event records' do
        aggregate = double('Aggregate')
        e1 = new_event_record(aggregate)
        e2 = new_event_record(aggregate)
        expect(event_record_repository).to receive(:save!).with(e1)
        expect(event_record_repository).to receive(:save!).with(e2)
        subject.commit_events([e1, e2])
      end

      it 'saves unique aggregates from all events' do
        aggregate = double('Aggregate1')
        aggregate2 = double('Aggregate2')

        e1 = new_event_record(aggregate)
        e2 = new_event_record(aggregate)
        e3 = new_event_record(aggregate2)

        expect(aggregate_repository).to receive(:save!).with(aggregate).once
        expect(aggregate_repository).to receive(:save!).with(aggregate2).once
        subject.commit_events([e1, e2, e3])
      end

      it 'persists event records and aggregates in a single transaction' do
        aggregate = double('Aggregate')
        allow(transaction_svc).to receive(:transaction) #no yield
        e1 = new_event_record(aggregate)
        expect(aggregate_repository).not_to receive(:save!)
        expect(event_record_repository).not_to receive(:save!)
        subject.commit_events([e1])
      end

      it 'uses prepared data for event payloads to avoid issues from events that would be invalid after going through serde' do
        e1 = new_event_record(double('Aggregate'), name: 'some/event', data: { foo: 'FOO' })
        expect(event_record_repository).to receive(:prepare_data).with(e1) do
          e1.data = { 'foo' => 'FOO' }
          e1
        end
        expect(event_factory).to receive(:new_event).with('some/event', { 'foo' => 'FOO' })
        subject.commit_events([e1])
      end
      #
      # it 'does no serde on record data for persisted records' do
      #   e1 = new_event_record(new_aggregate)
      #   e1.data = { amount: Money.new('10') }
      #   expect(e1).to receive(:persisted?).and_return(true)
      #   expect(events_factory).to receive(:new_event) do |_, data|
      #     expect(data).to eq(amount: Money.new('10'))
      #     double('Event').as_null_object
      #   end
      #   subject.commit_events([e1])
      # end
    end
  end
end
