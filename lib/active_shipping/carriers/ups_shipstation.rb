module ActiveShipping
  class UPSShipstation < Shipstation
    cattr_reader :name
    @@name = "UPS Shipstation"

    def service_mail_classes
      {
        "UPS Next Day Air®": "UPS_NEXT_DAY_AIR",
        "UPS Next Day Air® Early": "UPS_NEXT_DAY_AIR_EARLY",
        "UPS Next Day Air Saver®": "UPS_NEXT_DAY_AIR_SAVER",
        "UPS 2nd Day Air®": "UPS_SECOND_DAY_AIR",
        "UPS 3 Day Select®": "UPS_THIRD_DAY_SELECT",
        "UPS® Ground": "UPS_GROUND",
        "UPS Ground Saver": "UPS_GROUND_SAVER",
      }
    end

    def find_rates(origin, destination, packages, options = {})
      find_rates_from_shipstation(origin, destination, packages, "ups_walleted", options = {})
    end
  end
end
