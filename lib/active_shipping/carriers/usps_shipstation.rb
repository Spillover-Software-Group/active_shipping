module ActiveShipping
  class USPSShipstation < Carrier

    cattr_reader :name
    @@name = "USPS Shipstation"

    LIVE_URL = "https://ssapi.shipstation.com"

    SERVICE_MAIL_CLASSES = {
      "USPS First Class Mail - Letter": "usps_first_class_mail_letter",
      "USPS First Class Mail - Large Envelope or Flat": "usps_first_class_mail_large_envelope",
      "USPS First Class Mail - Package": "usps_first_class_mail_package",

      "USPS Priority Mail - Package": "usps_first_class_mail_package",
      "USPS Priority Mail - Medium Flat Rate Box": "usps_first_class_mail_medium_flat",
      "USPS Priority Mail - Small Flat Rate Box": "usps_first_class_mail_small_flat",
      "USPS Priority Mail - Large Flat Rate Box": "usps_first_class_mail_large_flat",
      "USPS Priority Mail - Flat Rate Envelope": "usps_first_class_mail_envolepe_flat",
      "USPS Priority Mail - Flat Rate Padded Envelope": "usps_first_class_mail_padded_envelope",
      "USPS Priority Mail - Legal Flat Rate Envelope": "usps_first_class_mail_legal_flat",


      "USPS Priority Mail Express - Package": "usps_first_class_mail_package",
      "USPS Priority Mail Express - Flat Rate Envelope": "usps_first_class_mail_flat_envelope",
      "USPS Priority Mail Express - Flat Rate Padded Envelope": "usps_first_class_mail_padded_envelope",
      "USPS Priority Mail Express - Legal Flat Rate Envelope": "usps_first_class_mail_legal_envelope",

      "USPS Media Mail - Package": "usps_media_mail",
      "USPS Parcel Select Ground - Package": "usps_parcel_select",
      "USPS Ground Advantage - Package": "usps_ground_advantage",
    }

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
        begin
          body = {
            carrierCode: "stamps_com",
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

      raise "THE RESULT FROM HERE #{package_rates}".inspect
    end

    private

    def generate_package_rates(response)
      service_rates = response.map do |service_type|
        {
          mail_class: SERVICE_MAIL_CLASSES[":#{service_type["serviceName"]}"],
          price: service_type["shipmentCost"]
        }
      end

      services_rates.compact!
    end

    def http_request(full_url, body, test = false)
      headers = {
        "Authorization" => "Basic #{credentials_base64}",
        "Content-type" => "application/json"
      }

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
