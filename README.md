# EventsFno

Ruby events from now on - A framework for 
introducing event sourcing to an already established system

Service level functionality is exposed via commands which act as
well defined input objects (i.e. Command objects).

Commands are executed against an aggregate and produce zero or more
`EventRecords` which contain all relevant facts as plain data,
not tailored to a particular persistence model (`CQRS`). 

This framework ensures that the events are persisted atomically 
with the changes to the write model. 


The event record stream can be tapped as necessary in addition
for other consumers and/or audit logs.

This architecture simplifies development by leading develepers to
focus things like:
 
* what actions/commands are needed by the applications
* what are the inputs required for those commands
* what are the potential event scenarios from a command (e.g. success?, 
  failure?) and what data s associated with each. 
* Last, and least, how those events apply to our specific model. 

Benefits:

* No upfront design of a specific persistence model
* A well defined architecture reducing time spent considering
  where to put your code, what abstractions, interfaces, etc.. (i.e. models, services, etc..)
* Minimal coupling and due to focus on inputs and scenarios instead 
  of persistence model.
* Baked in audit trail
* Potential to consume events for other purposes like
  different models (i.e. search indexes) or analytics,
* etc..

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'events_fno'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install events_fno

## Usage

e.g. For ActiveRecord

``` ruby
class CommandsSvc
  class Repository
    def save!(record)
      record.save!
    end

    def prepare_data(record)
      record.data = JSON.parse(record.data.to_json)
      record
    end
  end

  class << self
    def execute(aggregate, name:, data: {})
      repository = Repository.new
      EventsFno::Commander.new(event_factory: EventsFactory.new,
                               command_factory: CommandFactory.new,
                               transaction_svc: ActiveRecord::Base,
                               aggregate_repository: repository,
                               event_record_repository: repository)
          .execute(aggregate, name: name, data: data)
    end
  end

```

e.g. Command/Event factory

```ruby
class CommandFactory
  PAYLOAD_CLASSES = {
      'orders/pending_payment_create' => Orders::PendingPaymentCreate,
      'orders/log_external_event' => Orders::LogExternalEvent,
      'orders/subscriptions_schedule' => Orders::SubscriptionsSchedule,
  }

  def new_command(name, data)
    if (c = PAYLOAD_CLASSES[name])
      c.new(data)
    else
      raise "no command class found for #{name}"
    end
  end
end
```

e.g. Command base

```ruby
class BaseCommand
  include TypedModel::ModelBase

  def execute(order, _)
    []
  end

  protected

  def new_event(aggregate, name:, data:)
    EventRecord.new(aggregate: aggregate,
                    name: name,
                    data: data,
                    event_at: Time.zone.now,
                    created_by: Logging::ActionLogging.current_user)
  end
end
```

e.g. Event base

```ruby
class BaseEvent
  include TypedModel::ModelBase

  def apply(event_record)
    event_record.hydrated_data = self
    event_record.aggregate.apply_event(event_record)
  end
end
```

Optionally expose a nice high level API for clients

e.g.

```ruby
class OrdersSvc
  def create_pending_payments(order, invoice)
    CommandsSvc.execute(order, name: 'orders/pending_payment_create',
                        data: { order_number: order.order_number,
                                amount: invoice.total.to_s })
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lenny/events_fno.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
