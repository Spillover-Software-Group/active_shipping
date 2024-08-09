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
      [:client_id, :client_secret, :access_token]
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
      packages_rates = []

      packages.each_with_index do |package, index|
        # begin
          body = {
            originZIPCode: origin.zip,
            destinationZIPCode: destination.zip,
            weight: package.oz.to_f,
            length: package.inches(:length).to_f,
            width: package.inches(:width).to_f,
            height: package.inches(:height).to_f,
          }
    
          request = http_request(
            "https://api-cat.usps.com/prices/v3/total-rates/search",
            body.to_json,
            test: options[:test]
          )

          response = JSON.parse(request)
  
          package = {
            package: index,
            rates: generate_package_rates(response)
          }
  
          packages_rates << package
        # rescue StandardError => e
        #   # If for any reason the request fails, we return an error and display the message
        #   # "We are unable to calculate shipping rates for the selected items" to the user
        #   packages_rates = []
        #   break
        # end
      end

      if packages_rates.any?
        rate_estimates = generate_packages_rates_estimates(packages_rates).map do |service|
          RateEstimate.new(origin, destination, @@name, service[:mail_class],
            :service_code => service[:mail_class],
            :total_price => service[:price],
            :currency => "USD",
            :packages => packages
          )
        end        
      else
        success = false
        message = "An error occured. Please try again."
      end

      # RateResponse expectes a response object as third argument, but we don't have a single
      # response, so we are passing anything to fill the gap
      RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    end

    protected

    def generate_packages_rates_estimates(packages_rates)
      # We sum all the prices from the same service for each package
      # and return a single cost for each service
      total_prices = Hash.new(0)

      packages_rates.each do |package|
        package[:rates].each do |rate|
          total_prices[rate[:mail_class]] += rate[:price]
        end
      end

      total_prices.map { |mail_class, price| { mail_class: mail_class, price: price } }
    end

    def generate_package_rates(response)
      # USPS returns more than one from the same service
      # we find the minimun price for a service and return it
      services_rates = SERVICE_TYPES.map do |service_type|
        rates = response["rateOptions"].select do |option|
          option["rates"].any? { |rate| rate["mailClass"] == service_type }
        end

        next if rates.nil? || rates.empty?

        min_price_option = rates.min_by do |option|
          option["rates"].map { |rate| rate["price"] }.min
        end
        service_rate = min_price_option["rates"].first

        {
          mail_class: service_rate["mailClass"],
          price: service_rate["price"]
        }
      end

      services_rates.compact!
    end

    private

    def http_request(full_url, body, test = true)
      headers = {
        "Authorization" => "Bearer #{@options[:access_token]}",
        "Content-type" => "application/json"
      }

      request = ssl_post(full_url, body, headers)

    rescue ActiveUtils::ResponseError => e

      if e.message == "Failed with 401 Unauthorized"
        client_id = @options[:client_id]
        client_secret = @options[:client_secret]
        config = Spree::ActiveShippingConfiguration.new

        if client_id && client_secret
          begin
            params = {
              client_id: client_id,
              client_secret: client_secret, 
              grant_type: "client_credentials"
            }

            body = params.to_json
            headers = {
              "Content-Type" => "application/json"
            }

            new_token_response = ssl_post(
              "#{test ? TEST_URL : LIVE_URL}/oauth2/v3/token",
              body,
              headers
            )

            json = JSON.parse(new_token_response)

            @options[:access_token] = json["access_token"]

            raise "#{config} and #{config.usps_access_token}".inspect
            config.usps_access_token = @options[:access_token]

            request = ssl_post(full_url, body, headers)
          rescue ActiveUtils::ResponseError
            config.usps_access_token = nil
            config.usps_refresh_token = nil
            request
          end
        else
          config.usps_access_token = nil
          request
        end
      else
        request
      end
    end
  end
end
