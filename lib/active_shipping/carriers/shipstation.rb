module ActiveShipping
  class Shipstation < Carrier
    cattr_reader :name
    @@name = "Shipstation"

    LIVE_URL = "https://ssapi.shipstation.com"

    def requirements
      [:api_key, :api_secret]
    end

    def find_rates_from_shipstation(origin, destination, packages, carrier_code, options = {})
      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)
      
      success = true
      message = ''
      packages_rates = call_packages_rates(origin, destination, packages, carrier_code, options)

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

    private

    def call_packages_rates(origin, destination, packages, carrier_code, options = {})
      packages_rates = []
      packages.each_with_index do |package, index|
        begin
          body = {
            carrierCode: carrier_code,
            fromPostalCode: origin.zip,
            toState: origin.state,
            toCountry: origin.country_code,
            toPostalCode: destination.zip,
            weight: {
              value: package.oz.to_f,
              units: "ounces"
            },
            dimensions: {
              units: "inches",
              length: package.inches(:length).to_f,
              width: package.inches(:width).to_f,
              height: package.inches(:height).to_f,
            },
            residential: true
          }
    
          request = http_request(
            "#{LIVE_URL}/shipments/getrates",
            body.to_json,
          )

          response = JSON.parse(request)

          package = {
            package: index,
            rates: generate_package_rates(response)
          }

          packages_rates << package
        rescue StandardError => e
          # If for any reason the request fails, we return an error and display the message
          # "We are unable to calculate shipping rates for the selected items" to the user
          packages_rates = []
          break
        end
      end

      packages_rates
    end

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
      response.map do |service_type|
        {
          mail_class: service_mail_classes[:"#{service_type["serviceName"]}"],
          price: service_type["shipmentCost"]
        }
      end
    end

    def http_request(full_url, body, test = false)
      ssl_post(full_url, body, {
        "Authorization" => "Basic #{credentials_base64}",
        "Content-type" => "application/json"
      })
    end

    def credentials_base64
      credentials = "#{@options[:api_key]}:#{@options[:api_secret]}"
      Base64.strict_encode64(credentials)
    end
  end
end
