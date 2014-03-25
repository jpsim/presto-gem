# The Presto Gem

Gem for interacting with Presto cards.

## Usage

```ruby
require 'presto'

status = Presto::PrestoAPI.new.card_status_with_number('XXXXXXXXXXXXXXXXX')
puts status.balance
```

## License

MIT Licensed.

## Notice

Please respect the Presto website's [Terms and Conditions](https://www.prestocard.ca/en-US/Pages/ContentPages/Terms.aspx).
