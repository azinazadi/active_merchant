require File.dirname(__FILE__) + '/paymill/paymill_response'
require 'paymill'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaymillGateway < Gateway
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['DE']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.paymill.com/'

      # The name of the gateway
      self.display_name = 'Paymill'
      
      # Set default curreny to euro
      self.default_currency = 'EUR'

      def initialize(options = {})
        #requires!(options, :login, :password)
        super
      end

      def authorize(money, creditcard, options = {})
        ::Paymill.api_key = options[:api_key]
        
        timestamp = Time.now
        
        client = ::Paymill::Client.create(
          email: "#{options[:email]}"
        )

        unless client.id.nil?
          payment = ::Paymill::Payment.create(
            id: "pay_#{options[:order_id]}",
            client: client.id,
            card_type: creditcard.spree_cc_type, 
            token: options[:token],
            country: nil, 
            expire_month: creditcard.month, 
            expire_year: creditcard.year,
            card_holder: nil,
            last4: creditcard.display_number[15..18], 
            created_at: timestamp,
            updated_at: timestamp
          )

          unless payment.id.nil?
            preauth = ::Paymill::Preauthorization.create(
              payment: payment.id,
              amount: money,
              currency: "EUR"
            )

            unless preauth.id.nil?
              PaymillResponse.new(true, 'Paymill creating preauthorization successful', {amount: amount(money), payment_status: "Pending"}, :authorization => preauth.preauthorization["id"])
            else
              PaymillResponse.new(false, 'Paymill creating preauthorization unsuccessful')
            end

          else
            PaymillResponse.new(false, 'Paymill creating payment unsuccessful')
          end
        else
          PaymillResponse.new(false, 'Paymill creating client unsuccessful')
        end
      end
      
      def capture(money, authorization, options = {})
        ::Paymill.api_key = options[:api_key]
        
        transaction = ::Paymill::Transaction.create(
          amount: money,
          preauthorization: authorization,
          currency: "EUR"
        )
        
        unless transaction.id.nil?
          PaymillResponse.new(true, 'Paymill creating transaction successful', {amount: amount(money), payment_status: "Payed"}, :authorization => transaction.id)
        else
          PaymillResponse.new(false, 'Paymill creating transaction unsuccessful')
        end
      end
      
      def refund(refund_id, order, options = {})
        ::Paymill.api_key = options[:api_key]
        
        refund = ::Paymill::Refund.create(
          id: refund_id,
          amount: order[:subtotal].to_i
        )

        unless refund.id.nil?
          PaymillResponse.new(true, 'Paymill refund successful', {amount: amount(order[:subtotal].to_i), payment_status: "Refunded"}, :authorization => refund.id)
        else
          PaymillResponse.new(false, 'Paymill refund unsuccessful')
        end
      end

      private

      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)
      end

      def add_invoice(post, options)
      end

      def add_creditcard(post, creditcard)
      end

      def parse(body)
      end

      def commit(action, money, parameters)
      end

      def message_from(response)
      end

      def post_data(action, parameters = {})
      end
    end
  end
end

