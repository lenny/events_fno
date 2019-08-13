module EventsFno
  class Commander
    attr_reader :event_factory, :command_factory, :transaction_svc, :aggregate_repository, :event_record_repository

    def initialize(event_factory:,
                   command_factory:,
                   transaction_svc:,
                   aggregate_repository:,
                   event_record_repository:)
      @event_factory = event_factory
      @command_factory = command_factory
      @transaction_svc = transaction_svc
      @aggregate_repository = aggregate_repository
      @event_record_repository = event_record_repository
    end

    def execute(aggregate, name: name, data: data)
      event_committer = Support::EventsCommitter.new(event_factory: event_factory,
                                                     aggregate_repository: aggregate_repository,
                                                     event_record_repository: event_record_repository,
                                                     transaction_svc: transaction_svc)

      Support::CommandExecutor.new(command_factory: command_factory, events_committer: event_committer)
          .execute(aggregate, name: name, data: data)
    end
  end
end