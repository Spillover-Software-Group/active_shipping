# DOCS: https://developer.fedex.com/api/en-us/catalog/rate/v1/docs.html

module ActiveShipping
  class FedEx < Carrier
    self.retry_safe = true
    self.ssl_version = :TLSv1_2

    cattr_reader :name
    @@name = "FedEx"

    TEST_URL = 'https://apis-sandbox.fedex.com'
    LIVE_URL = 'https://apis.fedex.com'

    def requirements
      [:client_id, :client_secret, :client_account]
    end

    def find_rates(origin, destination, packages, options = {})
      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)

      get_rates(origin, destination, packages, options)
    end

    def get_rates(origin, destination, packages, options = {})
      success = true
      message = ''

      begin
        body = {
          accountNumber: {
            value: @options[:client_account],
          },
          requestedShipment: {
            shipper: {
              address: {
                postalCode: origin.zip,
                countryCode: "US"
              }
            },
            recipient: {
              address: {
              postalCode: destination.zip,
              countryCode: "US"
              }
            },
            pickupType: "DROPOFF_AT_FEDEX_LOCATION",
            rateRequestType: [
              "LIST",
              "ACCOUNT"
            ],
            # requestedPackageLineItems: [requestedPackageLineItems(packages)],
            requestedPackageLineItems: [{
              "weight": {
                "units": "LB",
                "value": 1.0
              }
            }]
          }
        }

         request = http_request(
            "#{options[:test] ? TEST_URL : LIVE_URL}/rate/v1/rates/quotes",
            body.to_json,
            test: options[:test]
         )

        response = JSON.parse(request)
        rate_estimates = get_rate_estimates(response, origin, destination, packages)
      rescue ActiveShipping::ResponseError => e
        # If for any reason the request fails, we return an error and display the message
        # "We are unable to calculate shipping rates for the selected items" to the user
        raise "FedEx API error: #{e.message}"
      end

      RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    end

    private

    def get_rate_estimates(response, origin, destination, packages)
      rate_reply_details = response.dig("output", "rateReplyDetails") || []

      rate_reply_details.map do |detail|
        mail_class = detail["serviceType"]
        rated_shipment = detail["ratedShipmentDetails"]&.first
        price = rated_shipment&.dig("totalNetFedExCharge")

        RateEstimate.new(origin, destination, @@name, mail_class,
          :service_code => mail_class,
          :total_price => price,
          :currency => "USD",
          :packages => packages
        )
      end
    end

    # Sum the lbs of all the packages and return a single object with the total weight
    def requestedPackageLineItems(packages)
      total_lbs = packages.sum { |package| package.lbs.to_f }

      {
        weight: {
          units: "LB",
          value: total_lbs
        }
      }
    end

    def http_request(full_url, body, test = false)
      Rails.logger.info "FEDEX BODY: #{JSON.pretty_generate(body)}"
      ssl_post(full_url, body, {
        "Authorization" => "Bearer #{access_token(test:)}",
        "Content-type" => "application/json"
      })
    rescue ActiveUtils::ResponseError => e
      Rails.logger.info "The body of the request was: #{body}"
      Rails.logger.error "FedEx API ERROR STATUS: #{e.response.code}"
      Rails.logger.error "FedEx API ERROR BODY: #{e.response.body}"
      Rails.logger.error "FedEx API ERROR MESSAGE: #{e.message}"

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
      client_id = @options[:client_id]
      client_secret = @options[:client_secret]

      # The access token is valid for 1 hour.
      Rails.cache.fetch("store_fedex_access_token:#{client_id}", expires_in: 59.minutes, force: renew) do
        response = ssl_post(
          "#{LIVE_URL}/oauth/token",
          {
            grant_type: "client_credentials",
            client_id: client_id,
            client_secret: client_secret
          }.to_query,
          { "Content-Type" => "application/x-www-form-urlencoded" }
        )

        JSON.parse(response).fetch("access_token")
      end
    end

    def handle_exception(e)
      ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
      raise e
    end
  end
end
