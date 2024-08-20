module ActiveShipping
  class USPSShipstation < ::ActiveShipping::Shipstation
    cattr_reader :name
    @@name = "USPS Shipstation"

    LIVE_URL = "https://ssapi.shipstation.com"

    SERVICE_MAIL_CLASSES = {
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
end
