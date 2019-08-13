module EventsFno
  module Contracts
    module CommandFactory
      def new_command(name, data)
        raise NotImplementedError
      end
    end

    module EventFactory
      def new_event(name, data)
        raise NotImplementedError
      end
    end

    module Command
      def valid?
        raise NotImplementedError
      end

      def execute(aggregate, context)
        raise NotImplementedError
      end
    end

    module EventRecord
      def aggregate
        raise NotImplementedError
      end

      def name
        raise NotImplementedError
      end

      def data
        raise NotImplementedError
      end
    end

    module AggregateRepository
      def save!(aggregate)
        raise NotImplementedError
      end
    end

    module EventRecordRepository
      def save!(event_record)
        raise NotImplementedError
      end

      def prepare_data(event_record)
        raise NotImplementedError
      end
    end

    module TransactionSvc
      def transaction(&blk)
        raise NotImplementedError
      end
    end
  end
end