module ActiveShipping
  class USPSRest < Carrier
    EventDetails = Struct.new(:description, :time, :zoneless_time, :location, :event_code)
    ONLY_PREFIX_EVENTS = ['DELIVERED','OUT FOR DELIVERY']
    self.retry_safe = true
    self.ssl_version = :TLSv1_2

    cattr_reader :name
    @@name = "USPS"

    LIVE_DOMAIN = 'production.shippingapis.com'
    LIVE_RESOURCE = 'ShippingAPI.dll'

    TEST_DOMAINS = { # indexed by security; e.g. TEST_DOMAINS[USE_SSL[:rates]]
      true => 'secure.shippingapis.com',
      false => 'stg-production.shippingapis.com'
    }

    MAIL_TYPES = {
      :package => 'Package',
      :postcard => 'Postcards or aerogrammes',
      :matter_for_the_blind => 'Matter for the blind',
      :envelope => 'Envelope'
    }

    PACKAGE_PROPERTIES = {
      'ZipOrigination' => :origin_zip,
      'ZipDestination' => :destination_zip,
      'Pounds' => :pounds,
      'Ounces' => :ounces,
      'Container' => :container,
      'Size' => :size,
      'Machinable' => :machinable,
      'Zone' => :zone,
      'Postage' => :postage,
      'Restrictions' => :restrictions
    }
    POSTAGE_PROPERTIES = {
      'MailService' => :service,
      'Rate' => :rate
    }

    US_SERVICES = {
      :first_class => 'FIRST CLASS',
      :priority => 'PRIORITY',
      :express => 'EXPRESS',
      :bpm => 'BPM',
      :parcel => 'PARCEL',
      :media => 'MEDIA',
      :library => 'LIBRARY',
      :online => 'ONLINE',
      :plus => 'PLUS',
      :all => 'ALL'
    }

    # Array of U.S. possessions according to USPS: https://www.usps.com/ship/official-abbreviations.htm
    US_POSSESSIONS = %w(AS FM GU MH MP PW PR VI)

    # Country names:
    # http://pe.usps.gov/text/Imm/immctry.htm
    COUNTRY_NAME_CONVERSIONS = {
      "BA" => "Bosnia-Herzegovina",
      "CD" => "Congo, Democratic Republic of the",
      "CG" => "Congo (Brazzaville),Republic of the",
      "CI" => "Côte d'Ivoire (Ivory Coast)",
      "CK" => "Cook Islands (New Zealand)",
      "FK" => "Falkland Islands",
      "GB" => "Great Britain and Northern Ireland",
      "GE" => "Georgia, Republic of",
      "IR" => "Iran",
      "KN" => "Saint Kitts (St. Christopher and Nevis)",
      "KP" => "North Korea (Korea, Democratic People's Republic of)",
      "KR" => "South Korea (Korea, Republic of)",
      "LA" => "Laos",
      "LY" => "Libya",
      "MC" => "Monaco (France)",
      "MD" => "Moldova",
      "MK" => "Macedonia, Republic of",
      "MM" => "Burma",
      "PN" => "Pitcairn Island",
      "RU" => "Russia",
      "SK" => "Slovak Republic",
      "TK" => "Tokelau (Union) Group (Western Samoa)",
      "TW" => "Taiwan",
      "TZ" => "Tanzania",
      "VA" => "Vatican City",
      "VG" => "British Virgin Islands",
      "VN" => "Vietnam",
      "WF" => "Wallis and Futuna Islands",
      "WS" => "Western Samoa"
    }

    def requirements
      [:client_id, :client_secret, :access_token]
    end

    def find_rates(origin, destination, packages, options = {})
      # raise "from USPSRest here origin: #{origin} and destination: #{destination} and packages: #{packages} and options: #{options}"

      options = @options.merge(options)

      origin = Location.from(origin)
      destination = Location.from(destination)
      packages = Array(packages)

      domestic_codes = US_POSSESSIONS + ['US', nil]
      if domestic_codes.include?(destination.country_code(:alpha2))
        us_rates(origin, destination, packages, options)
      else
        world_rates(origin, destination, packages, options)
      end
    end

    def us_rates(origin, destination, packages, options = {})
      body = {
        originZIPCode: "78705",
        destinationZIPCode: "78210",
        weight: 6.0,
        length: 20.0,
        width: 20.0,
        height: 5.0,
        mailClass: "PARCEL_SELECT",
        processingCategory: "NON_MACHINABLE",
        destinationEntryFacilityType: "NONE",
        rateIndicator: "DR",
        priceType: "COMMERCIAL"
      }

      request = http_client(
        "https://api-cat.usps.com/prices/v3/base-rates/search",
        body:,
      )

      # raise request.inspect

      request_body = {
        "totalBasePrice": 11.92,
        "rates": [
            {
                "SKU": "DUXR0XXXXC02130",
                "description": "USPS Ground Advantage Nonmachinable Dimensional Rectangular",
                "priceType": "COMMERCIAL",
                "price": 11.92,
                "weight": 6,
                "dimWeight": 13,
                "fees": [],
                "startDate": "2024-07-14",
                "endDate": "",
                "warnings": [],
                "mailClass": "USPS_GROUND_ADVANTAGE",
                "zone": "02"
            }
        ]
      }
      
      parse_rate_response(origin, destination, packages, request_body, options = {})
    end

    protected

    def parse_rate_response(origin, destination, packages, response, options = {})
      success = true
      message = ''
      rate_hash = {}

      # # TODO: if error
      # if request.status === 201
      # else
      #   rate_estimates = 
      # end
    end

    private

    def http_request(full_url, body)
      headers = {
        "Authorization" => "Bearer #{@options[:access_token]}",
        "Content-type" => "application/json"
      }

      response = ssl_post(full_url, body, headers)
      raise response.inspect
      
    end
  end
end
