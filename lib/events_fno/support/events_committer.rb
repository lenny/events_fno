module EventsFno
  module Support
    # Apply event_records to aggregates and persist aggregates with source event records atomically.
    class EventsCommitter
      attr_reader :event_factory, :transaction_svc, :aggregate_repository, :event_record_repository

      def initialize(event_factory:, transaction_svc:, aggregate_repository:,
                     event_record_repository:)
        @event_factory = event_factory
        @transaction_svc = transaction_svc
        @aggregate_repository = aggregate_repository
        @event_record_repository = event_record_repository
      end

      def commit_events(event_records)
        event_records.each do |event_record|
          apply_event(event_record)
        end

        transaction_svc.transaction do
          event_records.map(&:aggregate).uniq.each do |aggregate|
            aggregate_repository.save!(aggregate)
          end
          event_records.each do |record|
            event_record_repository.save!(record)
          end
        end
      end

      private

      # considered introducing an `ApplyEvent` collaborator, but decided it wasn't worth it's weight
      def apply_event(event_record)
        data = event_record_repository.prepare_data(event_record).data
        event = event_factory.new_event(event_record.name, data)
        if event.valid?
          event.apply(event_record)
        else
          raise "invalid event #{event.name} event: #{event.inspect}"
        end
      end
    end
  end
end
