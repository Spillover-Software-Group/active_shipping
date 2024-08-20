module ActiveShipping
  class UPSShipstation < Shipstation
    def requirements
      [:api_key, :api_secret]
    end

    def find_rates(origin, destination, packages, options = {})
      raise "GSUTAVO CAMELLO TEST".inspect
    end
  end
end
