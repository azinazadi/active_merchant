module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaymillResponse < Response
      def payment_status
        @params['payment_status']
      end
    end
  end
end
