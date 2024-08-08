module ActiveShipping
  class USPSRest < Carrier
    self.retry_safe = true
    self.ssl_version = :TLSv1_2

    cattr_reader :name
    @@name = "USPS"

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
      # raise "widht: #{packages.first.inches(:width)} / dimentions: #{packages.first} / weigth: #{packages.first.weight} packages: #{packages} / count: #{packages.count}".inspect
      success = true
      message = ''

      packages.each do |package|
        body = {
          originZIPCode: origin.zip,
          destinationZIPCode: destination.zip,
          weight: 6.0,
          length: 20.0,
          width: 20.0,
          height: 5.0,
        }

        request = http_request(
          "https://api-cat.usps.com/prices/v3/total-rates/search",
          body.to_json,
        )

        response = JSON.parse(request)
        raise "response #{response}".inspect
      end

      body = {
        originZIPCode: origin.zip,
        destinationZIPCode: destination.zip,
        weight: 6.0,
        length: 20.0,
        width: 20.0,
        height: 5.0,
      }

      request = http_request(
        "https://api-cat.usps.com/prices/v3/total-rates/search",
        body.to_json,
      )

      response = JSON.parse(request)

      if response["rateOptions"]
        rate_estimates = package_rate_estimates(origin, destination, packages, response, options = {})
        rate_estimates.compact!
      else
        success = false
        message = "An error occured. Please try again."
      end

      RateResponse.new(success, message, response, :rates => rate_estimates)
    end

    protected

    def package_rate_estimates(origin, destination, packages, response, options = {})
      SERVICE_TYPES.map do |service_type|
        rates = response["rateOptions"].select do |option|
          option["rates"].any? { |rate| rate["mailClass"] == service_type }
        end

        next if rates.nil? || rates.empty?

        min_price_option = rates.min_by do |option|
          option["rates"].map { |rate| rate["price"] }.min
        end
        service_rate = min_price_option["rates"].first

        RateEstimate.new(origin, destination, @@name, service_rate["mailClass"],
          :service_code => service_rate["mailClass"],
          :total_price => service_rate["price"],
          :currency => "USD",
          :packages => packages
        )
      end
    end

    # def parse_rate_response(origin, destination, packages, response, options = {})
    #   success = true
    #   message = ''
    #   rate_hash = {}

    #   if response["totalBasePrice"]
    #     rate_estimates = response["rates"].map do |rate|
    #       RateEstimate.new(origin, destination, @@name, service_name_for_code(rate["mailClass"]),
    #         :service_code => rate["mailClass"],
    #         :total_price => rate["price"],
    #         :currency => "USD",
    #         :packages => packages,
    #       )
    #     end

    #     rate_estimates.reject! { |e| e.package_count != packages.length }
    #     rate_estimates = rate_estimates.sort_by(&:total_price)
    #   else
    #     success = false
    #     message = "An error occured. Please try again."
    #   end

    #   RateResponse.new(success, message, response, rates: rate_estimates)
    # end

    private

    def service_name_for_code(service_code)
      SERVICE_TYPES[service_code] || service_name_for(service_code)
    end

    def service_name_for(code)
      formatted_name = code.gsub('_', ' ')
      formatted_name = formatted_name.split.map.with_index do |word, index|
        index == 0 && word.upcase == "USPS" ? word.upcase : word.capitalize
      end.join(' ')

      formatted_name
    end

    def http_request(full_url, body)
      headers = {
        "Authorization" => "Bearer #{@options[:access_token]}",
        "Content-type" => "application/json"
      }

      ssl_post(full_url, body, headers)
    end
  end
end
