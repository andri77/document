require 'nokogiri'

class XmlGenerator
  def self.generate(invoice)
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.Invoice(version: '1.0') {
        xml.Client {
          xml.Name invoice.client_name
        }
        xml.Currency invoice.currency
        xml.LineItems {
          invoice.item_count.times do |i|
            xml.Item(number: i + 1) {
              xml.Description "Service Item #{i + 1}"
              xml.UnitPrice invoice.unit_price.to_s
              xml.Quantity 1
            }
          end
        }
        xml.Total invoice.total.to_s
        xml.Status invoice.status
        xml.GeneratedAt invoice.created_at.to_s
      }
    end
    builder.to_xml
  end
end
