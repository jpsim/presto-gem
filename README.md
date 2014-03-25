# The Presto Gem

Gem for interacting with Presto cards. Currently supports the following features:

* Registered and unregistered cards (i.e. username/passwords or card numbers)
* Card Status
	* Status
	* Balance
* User Information
	* First Name
	* Last Name
	* Address 1
	* Address 2
	* City
	* Province
	* Country
	* Postal Code
	* Phone Number
	* Email
	* Security Question
	* Security Answer
* Transaction History
	* Date
	* Service Provider
	* Location
	* Type
	* Amount
	* Balance
	* Loyalty Month
	* Loyalty Trip
	* Loyalty Step
	* Loyalty Discount

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
