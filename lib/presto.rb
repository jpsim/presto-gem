require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'json'
require 'base64'

module Presto
  class CardStatus
    attr_accessor :balance, :status
  end

  class User
    attr_accessor :first_name,
      :last_name,
      :address,
      :apt,
      :city,
      :province,
      :country,
      :postal_code,
      :phone_number,
      :email,
      :security_question,
      :security_answer
  end

  class Transaction
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

  class CreditCard
    attr_accessor :name,
      :number,
      :expiry_month,
      :expiry_year
  end

  class PrestoAPI
    def user_with_username_password(username, password)
      login_with_username_password(username, password)
      user_from_page(agent.get('https://www.prestocard.ca/en-US/Pages/TransactionalPages/ViewUpdateRegistration.aspx'))
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

    def load_registered_card(username, password, email, amount, credit_card)
      login_with_username_password(username, password)
      load_card(amount, email, credit_card)
    end

    def load_unregistered_card(card_number, email, amount, credit_card)
      login_with_card_number(card_number)
      load_card(amount, email, credit_card)
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
      card_status = CardStatus.new
      card_status.status = status.content
      card_status.balance = balance.content
      card_status
    end

    def user_from_page(page)
      first_name = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelFirstNameOutput"]/text()[last()]').last
      last_name = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelLastNameOutput"]/text()[last()]').last
      address = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelStreetAddress1Output"]/text()[last()]').last
      apt = page.parser.xpath('//span[@id="ctl00_SPWebPartManager1_updateRegistrationWebPart_ctl00_WizardViewUpdateProfile_labelStreetAddress1Output"]/text()[last()]').last
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
      user.address = address.content || ''
      user.apt = apt.content || ''
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

    def load_card(amount, email, credit_card)
      # Check that we want to load a dollar value onto the card
      page = agent.get('https://www.prestocard.ca/en-US/Pages/TransactionalPages/ReloadEpurse.aspx')
      form = page.forms.first
      radio_button = form.radiobutton_with(:id => 'ctl00_SPWebPartManager1_LoadePurseWebPartWebpartControl_ctl00_wizardLoadEPurse_webpartPeriodPassWebPart_ctl00_wizardPeriodPassSelection_radioButtonListProducts_0')
      radio_button.check
      button = form.button_with(:name => "ctl00$SPWebPartManager1$LoadePurseWebPartWebpartControl$ctl00$wizardLoadEPurse$webpartPeriodPassWebPart$ctl00$wizardPeriodPassSelection$buttonNextinProductSelection")
      page = agent.submit(form, button)

      # Enter the amount to add to the card and our email address
      form = page.forms.first
      amount_field = form.field_with(:id => "ctl00_SPWebPartManager1_LoadePurseWebPartWebpartControl_ctl00_wizardLoadEPurse_textBoxamountToReload")
      amount_field.value = amount
      email_field = form.field_with(:id => "ctl00_SPWebPartManager1_LoadePurseWebPartWebpartControl_ctl00_wizardLoadEPurse_textBoxemailAddress")
      email_field.value = email
      button = form.button_with(:name => "ctl00$SPWebPartManager1$LoadePurseWebPartWebpartControl$ctl00$wizardLoadEPurse$buttonConfirmReload")
      page = agent.submit(form, button)

      # Confirm Amount
      form = page.forms.first
      button = form.button_with(:name => "ctl00$SPWebPartManager1$LoadePurseWebPartWebpartControl$ctl00$wizardLoadEPurse$buttonConfirmInVerification")
      page = agent.submit(form, button)

      # Intermediate Moneris Submit
      storeId = page.body[/storeId = '[^\s]*'/,0][/'.*'/,0][1..-2]
      hppKey = page.body[/hppKey = '[^\s]*'/,0][/'.*'/,0][1..-2]
      totalCharge = page.body[/totalCharge = '[^\s]*'/,0][/'.*'/,0][1..-2]
      orderId = page.body[/orderId = '[^\s]*'/,0][/'.*'/,0][1..-2]
      language = page.body[/language = '[^\s]*'/,0][/'.*'/,0][1..-2]

      form = page.forms.first
      form.field_with(:id => "ps_store_id").value = storeId
      form.field_with(:id => "hpp_key").value = hppKey
      form.field_with(:id => "charge_total").value = totalCharge
      form.field_with(:id => "order_id").value = orderId
      form.field_with(:id => "lang").value = language
      form.action = "https://www3.moneris.com/HPPDP/index.php"
      page = form.submit

      # Enter Payment Details
      callCCPurchase = page.body[/function callCCPurchase\(\)[^}]*/,0]

      hpp_id = callCCPurchase[/hpp_id=[^"]+/,0]
      hpp_id["hpp_id="] = ""
      hpp_ticket = callCCPurchase[/hpp_ticket=[^"]+/,0]
      hpp_ticket["hpp_ticket="] = ""
      pan = credit_card_number
      pan_mm = credit_card.expiry_month
      pan_yy = credit_card.expiry_year
      cardholder = credit_card.name

      post_data = "hpp_id=" + CGI::escape(hpp_id) +
        "&hpp_ticket=" + CGI::escape(hpp_ticket) +
        "&pan=" + CGI::escape(pan) +
        "&pan_mm=" + CGI::escape(pan_mm) +
        "&pan_yy=" + CGI::escape(pan_yy) +
        "&cardholder=" + CGI::escape(cardholder) +
        "&doTransaction=cc_purchase"

      # Send Payment
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded', 'Connection' => 'close', 'Content-length' => post_data.length }
      page = agent.post( 'https://www3.moneris.com/HPPDP/hprequest.php', post_data, headers)

      # Confirm with Credit Card Provider
      parsed = JSON.parse(page.body)
      form_text_encoded = parsed['response']['data']['form']
      form_text_decoded = Base64.decode64(form_text_encoded)

      # TODO: continue this method
    end

    def agent
      @agent ||= Mechanize.new
    end
  end
end
