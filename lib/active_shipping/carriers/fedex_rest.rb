# DOCS: https://developer.fedex.com/api/en-us/catalog/rate/v1/docs.html

module ActiveShipping
  class FedexRest < Carrier
    self.retry_safe = true
    self.ssl_version = :TLSv1_2

    cattr_reader :name
    @@name = "FedEx"

    TEST_URL = 'https://apis-sandbox.fedex.com'
    LIVE_URL = 'https://apis.fedex.com'

    SERVICE_TYPES = {
      "PRIORITY_OVERNIGHT" => "FedEx Priority Overnight",
      "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx Priority Overnight Saturday Delivery",
      "FEDEX_2_DAY" => "FedEx 2 Day",
      "FEDEX_2_DAY_SATURDAY_DELIVERY" => "FedEx 2 Day Saturday Delivery",
      "STANDARD_OVERNIGHT" => "FedEx Standard Overnight",
      "FIRST_OVERNIGHT" => "FedEx First Overnight",
      "FIRST_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx First Overnight Saturday Delivery",
      "FEDEX_EXPRESS_SAVER" => "FedEx Express Saver",
      "FEDEX_1_DAY_FREIGHT" => "FedEx 1 Day Freight",
      "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 1 Day Freight Saturday Delivery",
      "FEDEX_2_DAY_FREIGHT" => "FedEx 2 Day Freight",
      "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 2 Day Freight Saturday Delivery",
      "FEDEX_3_DAY_FREIGHT" => "FedEx 3 Day Freight",
      "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 3 Day Freight Saturday Delivery",
      "INTERNATIONAL_PRIORITY" => "FedEx International Priority",
      "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "FedEx International Priority Saturday Delivery",
      "INTERNATIONAL_ECONOMY" => "FedEx International Economy",
      "INTERNATIONAL_FIRST" => "FedEx International First",
      "INTERNATIONAL_PRIORITY_FREIGHT" => "FedEx International Priority Freight",
      "INTERNATIONAL_ECONOMY_FREIGHT" => "FedEx International Economy Freight",
      "GROUND_HOME_DELIVERY" => "FedEx Ground Home Delivery",
      "FEDEX_GROUND" => "FedEx Ground",
      "INTERNATIONAL_GROUND" => "FedEx International Ground",
      "SMART_POST" => "FedEx SmartPost",
      "FEDEX_FREIGHT_PRIORITY" => "FedEx Freight Priority",
      "FEDEX_FREIGHT_ECONOMY" => "FedEx Freight Economy"
    }

    def requirements
      [:client_id, :client_secret, :client_account]
    end

    def find_rates(origin, destination, packages, options = {})
    raise "#{packages.inspect} from find_rates active_shipping/carriers/fedex_rest.rb"
      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)

      get_rates(origin, destination, packages, options)
    end

    def get_rates(origin, destination, packages, options = {})
      success = true
      message = ''
      packages_rates = []

      begin
        body = {
          accountNumber: {
            value: @options[:client_account],
          },
          requestedShipment: {
            shipper: {
              address: {
              postalCode: origin.zip,
              countryCode: origin.country
              }
            },
            recipient: {
              address: {
              postalCode: destination.zip,
              countryCode: destination.country
              }
            },
            serviceType: options[:service_type],
            pickupType: "CONTACT_FEDEX_TO_SCHEDULE",
            requestedPackageLineItems: requestedPackageLineItems(packages),
            preferredCurrency: "USD"
          }
        }
        
        request = http_request(
          # "#{options[:test] ? TEST_URL : LIVE_URL}/rate/v1/rates/quotes",
          "#{TEST_URL}/rate/v1/rates/quotes",
          body.to_json,
          test: options[:test]
        )

        response = JSON.parse(request)
        Rails.logger.info("[FedexRest] rate response: #{response.inspect}")
        rate_estimates = get_rate_estimates(response)
        Rails.logger.info("[FedexRest] rate estimates: #{rate_estimates.inspect}")

      rescue ActiveShipping::ResponseError => e
         # If for any reason the request fails, we return an error and display the message
        # "We are unable to calculate shipping rates for the selected items" to the user
        raise e.inspect
        packages_rates = []
      end

      RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    end

    private

    def get_rate_estimates(response)
      # We generate a single cost for each service by summing the cost of each package
      # and return an array of RateEstimate with the cost for each service
      rate_reply_details = response.dig("output", "rateReplyDetails") || []

      rate_reply_details.map do |detail|
        mail_class = detail["serviceType"]
        rated_shipment = detail["ratedShipmentDetails"]&.first
        price = rated_shipment&.dig("totalNetFedExCharge")

        { mail_class: mail_class, price: price }
      end
    end

    def requestedPackageLineItems(packages)
      packages.map do |package|
        {
          weight: {
            units: "LB",
            value: package.lbs.to_f
          },
        }
      end
    end

    def http_request(full_url, body, test = false)
      ssl_post(full_url, body, {
        "Authorization" => "Bearer #{access_token(test:)}",
        "Content-type" => "application/json"
      })
    rescue ActiveUtils::ResponseError => e
      if e.message == "Failed with 401 Unauthorized"
        begin
          ssl_post(full_url, body, {
            "Authorization" => "Bearer #{access_token(renew: true, test:)}",
            "Content-type" => "application/json"
          })
        rescue ActiveUtils::ResponseError => e
          handle_exception(e)
        end
      else
        handle_exception(e)
      end
    end

    def access_token(renew: false, test: false)
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZSI6WyJDWFMtVFAiXSwiUGF5bG9hZCI6eyJjbGllbnRJZGVudGl0eSI6eyJjbGllbnRLZXkiOiJsNzZhNWU3ZmIzYzNjOTRkNmFhZjgxNGQ3YTZjZWJmYTJlIn0sImF1dGhlbnRpY2F0aW9uUmVhbG0iOiJDTUFDIiwiYWRkaXRpb25hbElkZW50aXR5Ijp7InRpbWVTdGFtcCI6IjAzLU1hci0yMDI2IDA0OjAwOjA2IEVTVCIsImdyYW50X3R5cGUiOiJjbGllbnRfY3JlZGVudGlhbHMiLCJhcGltb2RlIjoiU2FuZGJveCIsImN4c0lzcyI6Imh0dHBzOi8vY3hzYXV0aHNlcnZlci1zdGFnaW5nLmFwcC5wYWFzLmZlZGV4LmNvbS90b2tlbi9vYXV0aDIifSwicGVyc29uYVR5cGUiOiJEaXJlY3RJbnRlZ3JhdG9yX0IyQiJ9LCJleHAiOjE3NzI1MzIwMDYsImp0aSI6IjgwNjFjN2RjLTU2ODEtNDgxYi1hNjcyLWM4ZDU2NjE4MzA2NyJ9.zzvqwUcC4seTR4hIaNolFm4ZbwkYDHFsUiVcV1B4BCDsyIesceivPtPsWPs02ONGRhH6jpd22kUriR-tNBe0wTkkJkp3E29QcN-5zNol9n0SXCU0F0lKGQsxCbxL5by9pcUf1fCxoAjuV8XsKxi3RuKqBjgGXwMydChh8PHY_kvalMYMRNVMKFTX68wfgF0hXyp-D3EQcufmSsfPVdSqluQExNFCZryF9Y4EDYp5Bqo2nKNVgBBlC2B2ikyXDgtx0cIeP1oO9cQjbUnXH3e9ccE_BXfJoswWVpMb0B4QWK5gFJ6QlTC_xk9qrgix5rBDDZDAm1xODLA9dU7XgmVj1DYNHdBSAwW1KUDsw26p9mnmYpsbFczzv8NplOetO6xGb6kNgwP6Tf2_Bves5AddTkHjWOWl00FmR5hYslq__EseMFGLtGIn71O70lqlkq6NWCZXNNh-_ieyZZ3VfXdYQJ07XduRE449D2iOdn85l6l5WH5dQmAD7YxOskY0lo7dIM9-WQBN7gwbpjMd6D9QqlpbZsl_bZWl2sIz_k7OdTPxhINq8h5LHY6OUf84AhGX827dSAXagnN4JObpTM2ST_GXUcEQDNo4iCqr_aYvqvpxtMhOsNHKT3fZOGjm56JRRYp_Yzlejsn_9hI3yJ4kgUyEJrIyzi5Vsha17G4qxHw"
      # client_id = @options[:client_id]
      # client_secret = @options[:client_secret]

      # # The access token is valid for 1 hour.
      # Rails.cache.fetch("store_fedex_access_token:#{client_id}", expires_in: 59.minutes, force: renew) do
      #   response = ssl_post(
      #     # "#{LIVE_URL}/oauth/token",
      #     "#{TEST_URL}/oauth/token",
      #     {
      #       grant_type: "client_credentials",
      #       client_id: client_id,
      #       client_secret: client_secret
      #     }.to_query,
      #     { "Content-Type" => "application/x-www-form-urlencoded" }
      #   )

      #   Rails.logger.info("[FedexRest] access token response: #{response.inspect}")
      #   JSON.parse(response).fetch("access_token")
      # end
    end

    def handle_exception(e)
      ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
      raise
    end
  end
end
