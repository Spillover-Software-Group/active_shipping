module ActiveShipping
  class USPSShipstation < Carrier

    cattr_reader :name
    @@name = "USPS Shipstation"

    LIVE_URL = "https://ssapi.shipstation.com"

    def requirements
      [:api_key, :api_secret]
    end

    def find_rates(origin, destination, packages, options = {})
      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)
      
      success = true
      message = ''
      packages_rates = []

      packages.each_with_index do |package, index|
        # begin
          body = {
            carrier_code: "stamps_com",
            fromPostalCode: origin.zip,
            toState: origin.state,
            toCountry: origin.country[:codes].first[:value],
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

          raise "the request #{request}".inspect

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
    end

    private

    def http_request(full_url, body, test = false)
      headers = {
        "Authorization" => "Basic #{credentials_base64}",
        "Content-type" => "application/json"
      }

      raise "the body = #{body} and fullURL = #{full_url}".inspect

      request = ssl_post(full_url, body, headers)
      request
    end

    def credentials_base64
      api_key = "d0dbd6c655cd42d8a987fad03783a6b2"
      api_secret = "7b060e70eab94224bec70b5650def3d1"

      credentials = "#{api_key}:#{api_secret}"


      # credentials = "#{options[:api_key]}:#{options[:api_secret]}"
      Base64.strict_encode64(credentials)
    end
  end
end
