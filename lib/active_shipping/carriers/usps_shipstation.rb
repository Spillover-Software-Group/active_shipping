module ActiveShipping
  class USPSShipstation < Shipstation
    cattr_reader :name
    @@name = "USPS Shipstation"

    def service_mail_classes
      {
        "USPS First Class Mail - Letter": "USPS_FIRST_CLASS_MAIL_LETTER",
        "USPS First Class Mail - Large Envelope or Flat": "USPS_FIRST_CLASS_MAIL_LARGE_ENVELOPE",
        "USPS First Class Mail - Package": "USPS_FIRST_CLASS_MAIL_PACKAGE",
      
        "USPS Priority Mail - Package": "USPS_PRIORITY_MAIL_PACKAGE",
        "USPS Priority Mail - Medium Flat Rate Box": "USPS_PRIORITY_MAIL_MEDIUM_FLAT",
        "USPS Priority Mail - Small Flat Rate Box": "USPS_PRIORITY_MAIL_SMALL_FLAT",
        "USPS Priority Mail - Large Flat Rate Box": "USPS_PRIORITY_MAIL_LARGE_FLAT",
        "USPS Priority Mail - Flat Rate Envelope": "USPS_PRIORITY_MAIL_ENVOLEPE_FLAT",
        "USPS Priority Mail - Flat Rate Padded Envelope": "USPS_PRIORITY_MAIL_PADDED_ENVELOPE",
        "USPS Priority Mail - Legal Flat Rate Envelope": "USPS_PRIORITY_MAIL_LEGAL_FLAT",
      
        "USPS Priority Mail Express - Package": "USPS_PRIORITY_MAIL_EXPRESS_PACKAGE",
        "USPS Priority Mail Express - Flat Rate Envelope": "USPS_PRIORITY_MAIL_EXPRESS_FLAT_ENVELOPE",
        "USPS Priority Mail Express - Flat Rate Padded Envelope": "USPS_PRIORITY_MAIL_EXPRESS_PADDED_ENVELOPE",
        "USPS Priority Mail Express - Legal Flat Rate Envelope": "USPS_PRIORITY_MAIL_EXPRESS_LEGAL_ENVELOPE",
      
        "USPS Media Mail - Package": "USPS_MEDIA_MAIL",
        "USPS Parcel Select Ground - Package": "USPS_PARCEL_SELECT",
        "USPS Ground Advantage - Package": "USPS_GROUND_ADVANTAGE",
      }
    end

    def find_rates(origin, destination, packages, options = {})
      find_rates_from_shipstation(origin, destination, packages, "stamps_com", options = {})
    end

    # def find_rates(origin, destination, packages, options = {})
    #   options = @options.merge(options)

    #   origin = Location.from(origin)
    #   destination = Location.from(destination)
    #   packages = Array(packages)
      
    #   success = true
    #   message = ''
    #   packages_rates = call_packages_rates(origin, destination, packages, carrier_code, options)

    #   # packages.each_with_index do |package, index|
    #   #   begin
    #   #     body = {
    #   #       carrierCode: "stamps_com",
    #   #       fromPostalCode: origin.zip,
    #   #       toState: origin.state,
    #   #       toCountry: origin.country_code,
    #   #       toPostalCode: destination.zip,
    #   #       weight: {
    #   #         value: package.oz.to_f,
    #   #         units: "ounces"
    #   #       },
    #   #       dimensions: {
    #   #         units: "inches",
    #   #         length: package.inches(:length).to_f,
    #   #         width: package.inches(:width).to_f,
    #   #         height: package.inches(:height).to_f,
    #   #       },
    #   #       residential: true
    #   #     }
    
    #   #     request = http_request(
    #   #       "#{LIVE_URL}/shipments/getrates",
    #   #       body.to_json,
    #   #     )

    #   #     response = JSON.parse(request)

    #   #     package = {
    #   #       package: index,
    #   #       rates: generate_package_rates(response)
    #   #     }

    #   #     packages_rates << package
    #   #   rescue StandardError => e
    #   #     raise "error #{e} and message #{e&.message}".inspect
    #   #     # If for any reason the request fails, we return an error and display the message
    #   #     # "We are unable to calculate shipping rates for the selected items" to the user
    #   #     packages_rates = []
    #   #     break
    #   #   end
    #   # end

    #   if packages_rates.any?
    #     rate_estimates = generate_packages_rates_estimates(packages_rates).map do |service|
    #       RateEstimate.new(origin, destination, @@name, service[:mail_class],
    #         :service_code => service[:mail_class],
    #         :total_price => service[:price],
    #         :currency => "USD",
    #         :packages => packages
    #       )
    #     end
    #   else
    #     success = false
    #     message = "An error occured. Please try again."
    #   end

    #   # RateResponse expectes a response object as third argument, but we don't have a single
    #   # response, so we are passing anything to fill the gap
    #   RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    # end
  end
end
