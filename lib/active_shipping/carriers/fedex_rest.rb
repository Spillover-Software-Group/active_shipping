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
        
        # request = http_request(
        #   # "#{options[:test] ? TEST_URL : LIVE_URL}/rate/v1/rates/quotes",
        #   "#{TEST_URL}/rate/v1/rates/quotes",
        #   body.to_json,
        #   test: options[:test]
        # )

        request = {
          "transactionId": "APIF_SV_RATC_TxID3697f693-8ef8-4330-9643-1b5b26595716",
            "output": {
                "alerts": [
                    {
                        "code": "VIRTUAL.RESPONSE",
                        "message": "This is a Virtual Response.",
                        "alertType": "NOTE"
                    },
                    {
                        "code": "ORIGIN.STATEORPROVINCECODE.CHANGED",
                        "message": "The origin state/province code has been changed.",
                        "alertType": "NOTE"
                    },
                    {
                        "code": "DESTINATION.STATEORPROVINCECODE.CHANGED",
                        "message": "The destination state/province code has been changed.",
                        "alertType": "NOTE"
                    }
                ],
                "rateReplyDetails": [
                    {
                        "serviceType": "GROUND_HOME_DELIVERY",
                        "serviceName": "FedEx Home DeliveryÂ®",
                        "packagingType": "YOUR_PACKAGING",
                        "ratedShipmentDetails": [
                            {
                                "rateType": "ACCOUNT",
                                "ratedWeightMethod": "ACTUAL",
                                "totalDiscounts": 0.0,
                                "totalBaseCharge": 15.88,
                                "totalNetCharge": 48.33,
                                "totalNetFedExCharge": 48.33,
                                "shipmentRateDetail": {
                                    "rateZone": "4",
                                    "dimDivisor": 0,
                                    "fuelSurchargePercent": 15.0,
                                    "totalSurcharges": 32.45,
                                    "totalFreightDiscount": 0.0,
                                    "surCharges": [
                                        {
                                            "type": "FUEL",
                                            "description": "Fuel Surcharge",
                                            "level": "PACKAGE",
                                            "amount": 6.3
                                        },
                                        {
                                            "type": "RESIDENTIAL_DELIVERY",
                                            "description": "Residential surcharge",
                                            "level": "PACKAGE",
                                            "amount": 5.15
                                        },
                                        {
                                            "type": "HOME_DELIVERY_APPOINTMENT",
                                            "description": "FedEx Appointment Home Delivery",
                                            "level": "SHIPMENT",
                                            "amount": 21.0
                                        }
                                    ],
                                    "totalBillingWeight": {
                                        "units": "LB",
                                        "value": 10.0
                                    },
                                    "currency": "USD"
                                },
                                "ratedPackages": [
                                    {
                                        "groupNumber": 0,
                                        "effectiveNetDiscount": 0.0,
                                        "packageRateDetail": {
                                            "rateType": "PAYOR_ACCOUNT_PACKAGE",
                                            "ratedWeightMethod": "ACTUAL",
                                            "baseCharge": 15.88,
                                            "netFreight": 15.88,
                                            "totalSurcharges": 32.45,
                                            "netFedExCharge": 48.33,
                                            "totalTaxes": 0.0,
                                            "netCharge": 48.33,
                                            "totalRebates": 0.0,
                                            "billingWeight": {
                                                "units": "LB",
                                                "value": 10.0
                                            },
                                            "totalFreightDiscounts": 0.0,
                                            "surcharges": [
                                                {
                                                    "type": "FUEL",
                                                    "description": "Fuel Surcharge",
                                                    "level": "PACKAGE",
                                                    "amount": 6.3
                                                },
                                                {
                                                    "type": "RESIDENTIAL_DELIVERY",
                                                    "description": "Residential surcharge",
                                                    "level": "PACKAGE",
                                                    "amount": 5.15
                                                },
                                                {
                                                    "type": "HOME_DELIVERY_APPOINTMENT",
                                                    "description": "FedEx Appointment Home Delivery",
                                                    "level": "SHIPMENT",
                                                    "amount": 21.0
                                                }
                                            ],
                                            "currency": "USD"
                                        }
                                    }
                                ],
                                "currency": "USD"
                            },
                            {
                                "rateType": "LIST",
                                "ratedWeightMethod": "ACTUAL",
                                "totalDiscounts": 0.0,
                                "totalBaseCharge": 15.88,
                                "totalNetCharge": 48.33,
                                "totalNetFedExCharge": 48.33,
                                "shipmentRateDetail": {
                                    "rateZone": "4",
                                    "dimDivisor": 0,
                                    "fuelSurchargePercent": 15.0,
                                    "totalSurcharges": 32.45,
                                    "totalFreightDiscount": 0.0,
                                    "surCharges": [
                                        {
                                            "type": "FUEL",
                                            "description": "Fuel Surcharge",
                                            "level": "PACKAGE",
                                            "amount": 6.3
                                        },
                                        {
                                            "type": "RESIDENTIAL_DELIVERY",
                                            "description": "Residential surcharge",
                                            "level": "PACKAGE",
                                            "amount": 5.15
                                        },
                                        {
                                            "type": "HOME_DELIVERY_APPOINTMENT",
                                            "description": "FedEx Appointment Home Delivery",
                                            "level": "SHIPMENT",
                                            "amount": 21.0
                                        }
                                    ],
                                    "totalBillingWeight": {
                                        "units": "LB",
                                        "value": 10.0
                                    },
                                    "currency": "USD"
                                },
                                "ratedPackages": [
                                    {
                                        "groupNumber": 0,
                                        "effectiveNetDiscount": 0.0,
                                        "packageRateDetail": {
                                            "rateType": "PAYOR_LIST_PACKAGE",
                                            "ratedWeightMethod": "ACTUAL",
                                            "baseCharge": 15.88,
                                            "netFreight": 15.88,
                                            "totalSurcharges": 32.45,
                                            "netFedExCharge": 48.33,
                                            "totalTaxes": 0.0,
                                            "netCharge": 48.33,
                                            "totalRebates": 0.0,
                                            "billingWeight": {
                                                "units": "LB",
                                                "value": 10.0
                                            },
                                            "totalFreightDiscounts": 0.0,
                                            "surcharges": [
                                                {
                                                    "type": "FUEL",
                                                    "description": "Fuel Surcharge",
                                                    "level": "PACKAGE",
                                                    "amount": 6.3
                                                },
                                                {
                                                    "type": "RESIDENTIAL_DELIVERY",
                                                    "description": "Residential surcharge",
                                                    "level": "PACKAGE",
                                                    "amount": 5.15
                                                },
                                                {
                                                    "type": "HOME_DELIVERY_APPOINTMENT",
                                                    "description": "FedEx Appointment Home Delivery",
                                                    "level": "SHIPMENT",
                                                    "amount": 21.0
                                                }
                                            ],
                                            "currency": "USD"
                                        }
                                    }
                                ],
                                "currency": "USD"
                            }
                        ],
                        "operationalDetail": {
                            "ineligibleForMoneyBackGuarantee": false,
                            "astraDescription": "FXH",
                            "airportId": "DFW",
                            "serviceCode": "90"
                        },
                        "signatureOptionType": "SERVICE_DEFAULT",
                        "serviceDescription": {
                            "serviceId": "EP1000000133",
                            "serviceType": "GROUND_HOME_DELIVERY",
                            "code": "90",
                            "names": [
                                {
                                    "type": "long",
                                    "encoding": "utf-8",
                                    "value": "FedEx Home DeliveryÂ®"
                                },
                                {
                                    "type": "long",
                                    "encoding": "ascii",
                                    "value": "FedEx Home Delivery"
                                },
                                {
                                    "type": "medium",
                                    "encoding": "utf-8",
                                    "value": "Home DeliveryÂ®"
                                },
                                {
                                    "type": "medium",
                                    "encoding": "ascii",
                                    "value": "Home Delivery"
                                },
                                {
                                    "type": "short",
                                    "encoding": "utf-8",
                                    "value": "HD"
                                },
                                {
                                    "type": "short",
                                    "encoding": "ascii",
                                    "value": "HD"
                                },
                                {
                                    "type": "abbrv",
                                    "encoding": "ascii",
                                    "value": "QH"
                                }
                            ],
                            "description": "FedEx Home Delivery",
                            "astraDescription": "FXH"
                        }
                    }
                ],
                "quoteDate": "2026-03-03",
                "encoded": false
            }
        }

        response = JSON.parse(request)
        Rails.logger.info("[FedexRest] rate response: #{response.inspect}")
        rate_estimates = get_rate_estimates(response)
        Rails.logger.info("[FedexRest] rate estimates: #{rate_estimates.inspect}")

      rescue ActiveShipping::ResponseError => e
         # If for any reason the request fails, we return an error and display the message
        # "We are unable to calculate shipping rates for the selected items" to the user
        raise "FedEx API error: #{e.message}"
        packages_rates = []
      end

      RateResponse.new(success, message, { response: success }, :rates => rate_estimates)
    end

    private

    def get_rate_estimates(response)
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
      raise "full_url: #{full_url}, body: #{body.inspect}"
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
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZSI6WyJDWFMtVFAiXSwiUGF5bG9hZCI6eyJjbGllbnRJZGVudGl0eSI6eyJjbGllbnRLZXkiOiJsNzZhNWU3ZmIzYzNjOTRkNmFhZjgxNGQ3YTZjZWJmYTJlIn0sImF1dGhlbnRpY2F0aW9uUmVhbG0iOiJDTUFDIiwiYWRkaXRpb25hbElkZW50aXR5Ijp7InRpbWVTdGFtcCI6IjAzLU1hci0yMDI2IDA0OjQzOjMzIEVTVCIsImdyYW50X3R5cGUiOiJjbGllbnRfY3JlZGVudGlhbHMiLCJhcGltb2RlIjoiU2FuZGJveCIsImN4c0lzcyI6Imh0dHBzOi8vY3hzYXV0aHNlcnZlci1zdGFnaW5nLmFwcC5wYWFzLmZlZGV4LmNvbS90b2tlbi9vYXV0aDIifSwicGVyc29uYVR5cGUiOiJEaXJlY3RJbnRlZ3JhdG9yX0IyQiJ9LCJleHAiOjE3NzI1MzQ2MTMsImp0aSI6ImE3ODMyNWRmLTEwNWYtNGRlZC05MGRkLTRjZDNlYzVlNDg3YyJ9.k2vpfbCMJmZNedXjLfm7S92gchkLS6S5jeq9rn24U7rfybe7VQMb5iWFWbtrERQceHZlBj0Af7Ml0EoCGwik8Dqpj70AWp1y1rhq1NP4Wz3NvJ8AYbpMM1A2J9oElyPfXlYPiRXQZKNeRBHCGKXgMGHnqxy_BPB9M64AqI_i453L5vq2nP8RNyVsX16vIryu9dinxcQL7gn7l2C1gaGdKzHhNMZKS6zIZuA7vln1DzlmagF_RHjslX_13nuGVoMlK1uvKVaQJpFGLxxstgf5d1UXrJ5o9lPHImUezpKMcGPjLRRDidh1AaoAOpzcvPhk3aU_N5w1bBz8Pq26PoB7_BxfhoilvQySdUYKluY0Tlk5FRIzd3a30H1fCuL1mmX61dOb5rRx6_nmRBP5ezFcywiAiTcO1G_unWIPomnRpsmdv55QUu8N2RSMQgd0muYbh6LDvTMBE_LL6_4g4EP0EhxAAfBpg5Ll6zBFgLzjRxely_E22qi7zU_2Q0riphZ5CgmAEESiuwdvuxwxqIykwXUj2aaNHD81RMy-Q09B6OKkAiHoSnPxajPs4vkUb_GE3uUXLgh6viC_bmPgsGiNNXCaWoK0AJK3dfl7idjlNbcghb3OpxkGOPtjVabz8L2IXRXLV4MNuJ2rculy6k9JVnmDF4072DEhRPXKMc7GuA8"
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
    end
  end
end
