require 'rubygems'
require 'mechanize'

module PrestoAPI
  class Base
    def to_json
      hash = {}
      self.instance_variables.each do |var|
        # Remove @ symbol from var name
        key = var.to_s[1..-1]
        hash[key] = self.instance_variable_get var
      end
      hash.to_json
    end

    def from_json! string
      JSON.load(string).each do |var, val|
        self.instance_variable_set var, val
      end
    end
  end

  class Card < Base
    attr_accessor :number, :balance, :status
  end

  class User < Base
    attr_accessor :first_name,
      :card_number,
      :last_name,
      :address1,
      :address2,
      :city,
      :province,
      :country,
      :postal_code,
      :phone_number,
      :email,
      :security_question,
      :security_answer
  end

  class Transaction < Base
    attr_accessor :date,
      :service_provider,
      :location,
      :type,
      :amount,
      :balance,
      :loyalty_month,
      :loyalty_trip,
      :loyalty_step,
      :loyalty_discount
  end

  class Client
    def user_with_username_password(username, password)
      card_number = card_number_from_page(login_with_username_password(username, password))
      user = user_from_page(agent.get('https://www.prestocard.ca/en-US/Pages/TransactionalPages/ViewUpdateRegistration.aspx'))
      user.card_number = card_number
      user
    end

    def transaction_history_with_username_password(username, password)
      login_with_username_password(username, password)
      transaction_history_from_page(agent.get('https://www.prestocard.ca/en-US/Pages/TransactionalPages/TransactionHistory.aspx'))
    end

    def card_status_with_username_password(username, password)
      card_status_from_page(login_with_username_password(username, password))
    end

    def card_status_with_number(card_number)
      card_status_from_page(login_with_card_number(card_number))
    end

    private

    def login_with_username_password(username, password)
      # Fill out the registered login form
      field_hash = {
        'ctl00$SPWebPartManager1$AccountLoginWebpartControl$ctl00$webpartRegisteredUserLogin$ctl00$textboxRegisteredLogin' => username,
        'ctl00$SPWebPartManager1$AccountLoginWebpartControl$ctl00$webpartRegisteredUserLogin$ctl00$textboxPassword' => password
      }
      button_name = 'ctl00$SPWebPartManager1$AccountLoginWebpartControl$ctl00$webpartRegisteredUserLogin$ctl00$buttonSubmit'
      submit_form(login_page.forms.first, field_hash, button_name)
    end

    def login_with_card_number(card_number)
      # Fill out the anonymous login form
      field_hash = {
        'ctl00$SPWebPartManager1$AccountLoginWebpartControl$ctl00$webpartAnonymousUserLogin$ctl00$textboxAnonymousLogin' => card_number
      }
      button_name = 'ctl00$SPWebPartManager1$AccountLoginWebpartControl$ctl00$webpartAnonymousUserLogin$ctl00$buttonSubmit'
      submit_form(login_page.forms.first, field_hash, button_name)
    end

    def login_page
      @login_page ||= agent.get('https://www.prestocard.ca/en-US/Pages/TransactionalPages/AccountLogin.aspx')
    end

    def submit_form(form, field_hash, button_name)
      field_hash.each do |key, value|
        form.field_with(:name => key).value = value
      end
      button = form.button_with(:name => button_name)
      agent.submit(form, button)
    end

    def card_status_from_page(page)
      balance = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_AFMSCardSummaryWebpart_ctl00_wizardCardSummary_labelDisplayBalance"]/text()[last()]').last
      status = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_AFMSCardSummaryWebpart_ctl00_wizardCardSummary_labelDisplayCardStatus"]/text()[last()]').last
      if !balance || !status
        puts 'Try logging in with username/password instead of just the card number'
        return nil
      end
      card = Card.new
      card.status = status.content
      card.balance = balance.content
      card.number = card_number_from_page(page)
      card
    end

    def user_from_page(page)
      first_name = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelFirstNameOutput"]/text()[last()]').last
      last_name = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelLastNameOutput"]/text()[last()]').last
      address1 = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelStreetAddress1Output"]/text()[last()]').last
      address2 = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelStreetAddress2Output"]/text()[last()]').last
      city = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelCityOutput"]/text()[last()]').last
      province = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelProvinceOutput"]/text()[last()]').last
      country = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelCountryOutput"]/text()[last()]').last
      postal_code = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelPostalCodeOutput"]/text()[last()]').last
      phone_number = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelPrimaryTelephoneNumberOutput"]/text()[last()]').last
      email = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelEmailAddressOutput"]/text()[last()]').last
      security_question = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_webPartSecurityDetails_ctl00_labelSecurityQuestionOutput"]/text()[last()]').last
      security_answer = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_webPartSecurityDetails_ctl00_labelSecurityResponseOutput"]/text()[last()]').last

      if !first_name
        puts 'There is no user information assigned to this account'
        return nil
      end

      user = User.new
      user.first_name = first_name.content || ''
      user.last_name = last_name.content || ''
      user.address1 = address1.content || ''
      user.address2 = address2.content || ''
      user.city = city.content || ''
      user.province = province.content || ''
      user.country = country.content || ''
      user.postal_code = postal_code.content || ''
      user.phone_number = phone_number.content || ''
      user.email = email.content || ''
      user.security_question = security_question.content || ''
      user.security_answer = security_answer.content || ''
      user
    end

    def card_number_from_page(page)
      card_number = page.parser.xpath('//span[@id="ctl00_PlaceHolderContent_PlaceHolderSiteNavigation_CardNavigationMenuWebPart_ctl00_labelFareCardNo"]/text()[last()]').last.content
      card_number[/^\d+/].to_s
    end

    def transaction_history_from_page(page)
      number_of_items = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']").children.count
      transaction_history = []
      for i in 2..number_of_items
        transaction = Transaction.new
        transaction.date = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[1]").last.content
        transaction.service_provider = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[2]").last.content
        transaction.location = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[3]").last.content
        transaction.type = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[4]").last.content
        transaction.amount = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[5]").last.content
        transaction.balance = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[6]").last.content
        transaction.loyalty_month = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[7]").last.content
        transaction.loyalty_trip = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[8]").last.content
        transaction.loyalty_step = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[9]").last.content
        transaction.loyalty_discount = page.parser.xpath("//table[@id='ctl00_SPWebPartManager1_CheckTransactionHistoryWebPartControl_ctl00_ViewTransactionHistory_gridTransactionHistory']/tr[#{i}]/td[10]").last.content
        transaction_history.push transaction
      end
      transaction_history
    end

    def agent
      @agent ||= Mechanize.new
    end
  end
end
