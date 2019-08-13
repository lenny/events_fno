module EventsFno
  module Support
    class CommandExecutor
      attr_reader :command_factory, :events_committer

      def initialize(command_factory:, events_committer:)
        @command_factory = command_factory
        @events_committer = events_committer
      end

      def execute(aggregate, name:, data: {})
        command = command_factory.new_command(name, data)

        raise "invalid command #{name} event: #{command.inspect}" unless command.valid?

        event_records = command.execute(aggregate, {})

        events_committer.commit_events(event_records)

        event_records
      end
    end
  end
end