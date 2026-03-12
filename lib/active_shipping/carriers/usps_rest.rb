# DOCS: https://developers.usps.com/domesticpricesv3#tag/Resources/operation/post-total-rates-search

module ActiveShipping
  class USPSRest < Carrier
    self.retry_safe = true
    self.ssl_version = :TLSv1_2

    cattr_reader :name
    @@name = "USPS"

    TEST_URL = 'https://api-cat.usps.com'
    LIVE_URL = 'https://api.usps.com'

    # Array of U.S. possessions according to USPS: https://www.usps.com/ship/official-abbreviations.htm
    US_POSSESSIONS = %w(AS FM GU MH MP PW PR VI)

    VALID_RATE_INDICATORS = %w[SP EX] # SP = Single-piece, EX = Priority Express, etc.

    SERVICE_TYPES = [
      "PARCEL_SELECT",
      "PARCEL_SELECT_LIGHTWEIGHT",
      "PRIORITY_MAIL_EXPRESS",
      "PRIORITY_MAIL",
      "FIRST-CLASS_PACKAGE_SERVICE",
      "LIBRARY_MAIL",
      "MEDIA_MAIL",
      "BOUND_PRINTED_MATTER",
      "USPS_CONNECT_LOCAL",
      "USPS_CONNECT_MAIL",
      "USPS_CONNECT_NEXT_DAY",
      "USPS_CONNECT_REGIONAL",
      "USPS_CONNECT_SAME_DAY",
      "USPS_GROUND_ADVANTAGE",
      "USPS_RETAIL_GROUND",
    ]

    def requirements
      [:client_id, :client_secret]
    end

    def find_rates(origin, destination, packages, options = {})
      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)

      us_rates(origin, destination, packages, options)
    end

    def us_rates(origin, destination, packages, options = {})
      success = true
      message = ''
      rate_estimates = nil

      total_weight = packages.sum { |p| p.lbs.to_f }
      largest_package = packages.max_by { |p| p.inches(:length).to_f * p.inches(:width).to_f * p.inches(:height).to_f }

      body = {
        originZIPCode: origin.zip,
        destinationZIPCode: destination.zip,
        weight: total_weight,
        length: largest_package.inches(:length).to_f,
        width: largest_package.inches(:width).to_f,
        height: largest_package.inches(:height).to_f,
      }

      Rails.logger.info "USPS REST API request: origin=#{origin.zip}, destination=#{destination.zip}, body=#{body.inspect}"

      begin
        request = http_request(
          "#{options[:test] ? TEST_URL : LIVE_URL}/prices/v3/total-rates/search",
          body.to_json,
          test: options[:test]
        )

        Rails.logger.info "USPS REST API response: #{request.inspect}"
        response = JSON.parse(request)
        Rails.logger.info "USPS REST API response: #{response.inspect}"

        rates = generate_package_rates(response)

        rate_estimates = rates.map do |rate|
          RateEstimate.new(origin, destination, @@name, rate[:mail_class],
            :service_code => rate[:mail_class],
            :total_price => rate[:price],
            :currency => "USD",
            :packages => packages
          )
        end
      rescue StandardError => e
        # If for any reason the request fails, we return an error and display the message
        # "We are unable to calculate shipping rates for the selected items" to the user
        success = false
        message = "An error occured. Please try again."
        Rails.logger.error "USPS REST API error: #{e.message}"
      end

      success = false if rate_estimates.nil? || rate_estimates.empty?
      message = "An error occured. Please try again." unless success

      # RateResponse expectes a response object as third argument, but we don't have a single
      # response, so we are passing anything to fill the gap
      RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    end

    protected

    def generate_package_rates(response)
      services_rates = SERVICE_TYPES.map do |service_type|
        rates = response["rateOptions"].select do |option|
          rate = option["rates"].first

          rate["mailClass"] == service_type &&
          rate["processingCategory"] == "MACHINABLE" &&
          VALID_RATE_INDICATORS.include?(rate["rateIndicator"])
        end

        next if rates.empty?

        min_price_option = rates.min_by { |option| option["totalPrice"] }
        service_rate = min_price_option["rates"].first

        {
          mail_class: service_rate["mailClass"],
          price: service_rate["price"]
        }
      end

      services_rates.compact
    end

    private

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
      client_id = @options[:client_id]
      client_secret = @options[:client_secret]

      # From my testing, the access token is valid for 8 hours.
      Rails.cache.fetch("store_usps_access_token:#{client_id}", expires_in: 7.hours, force: renew) do
        response = ssl_post(
          "#{LIVE_URL}/oauth2/v3/token",
          {
            grant_type: "client_credentials",
            client_id: client_id,
            client_secret: client_secret
          }.to_json,
          { "Content-Type" => "application/json" }
        )

        JSON.parse(response).fetch("access_token")
      end
    end

    def handle_exception(e)
      ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
      raise
    end
  end
end
