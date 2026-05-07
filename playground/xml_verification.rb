require 'nokogiri'

XML_BODY = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <PurchaseOrder version="2.1" status="confirmed" currency="AUD">
    <OrderId>PO-20260507-001</OrderId>
    <CreatedAt>2026-05-07T09:30:00Z</CreatedAt>

    <Customer id="C-991" tier="gold">
      <FullName>Jane Andersen</FullName>
      <Email>jane@example.com</Email>
      <Phone countryCode="+61">412345678</Phone>
      <Address type="billing">
        <Street>42 George St</Street>
        <City>Sydney</City>
        <State>NSW</State>
        <PostCode>2000</PostCode>
        <Country>Australia</Country>
      </Address>
    </Customer>

    <Shipment method="express">
      <TrackingNumber>AUS-TRK-88821</TrackingNumber>
      <EstimatedDelivery>2026-05-10</EstimatedDelivery>
      <Weight unit="kg">3.75</Weight>
    </Shipment>

    <LineItems count="3">
      <Item sku="PRD-001" taxable="true">
        <Description>Wireless Keyboard</Description>
        <Quantity>2</Quantity>
        <UnitPrice>89.99</UnitPrice>
        <Discount percent="10">18.00</Discount>
        <Subtotal>161.98</Subtotal>
      </Item>
      <Item sku="PRD-002" taxable="true">
        <Description>USB-C Hub 7-Port</Description>
        <Quantity>1</Quantity>
        <UnitPrice>59.95</UnitPrice>
        <Discount percent="0">0.00</Discount>
        <Subtotal>59.95</Subtotal>
      </Item>
      <Item sku="PRD-003" taxable="false">
        <Description>Extended Warranty 2yr</Description>
        <Quantity>1</Quantity>
        <UnitPrice>29.00</UnitPrice>
        <Discount percent="0">0.00</Discount>
        <Subtotal>29.00</Subtotal>
      </Item>
    </LineItems>

    <Totals>
      <SubTotal>250.93</SubTotal>
      <TaxRate percent="10">22.19</TaxRate>
      <ShippingCost>15.00</ShippingCost>
      <GrandTotal>288.12</GrandTotal>
    </Totals>

    <Notes>
      <Note priority="high">Fragile items — handle with care</Note>
      <Note priority="low">Leave at door if no answer</Note>
    </Notes>
  </PurchaseOrder>
XML

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

PASS = "\e[32mPASS\e[0m"
FAIL = "\e[31mFAIL\e[0m"
$failures = 0

def check(description, actual, expected)
  if actual == expected
    puts "  #{PASS}  #{description}"
  else
    puts "  #{FAIL}  #{description}"
    puts "         expected: #{expected.inspect}"
    puts "           actual: #{actual.inspect}"
    $failures += 1
  end
end

def section(title)
  puts "\n#{title}"
  puts "-" * title.length
end

# ─────────────────────────────────────────────────────────────────────────────
# TESTS
# ─────────────────────────────────────────────────────────────────────────────

section("XML — Document structure")

doc = Nokogiri::XML(XML_BODY.strip) { |config| config.strict }
check("Parses without errors",          doc.errors.empty?,                                    true)

root = doc.at_css("PurchaseOrder")
check("Root element is PurchaseOrder",  root.name,                                            "PurchaseOrder")
check("version attribute is 2.1",       root["version"],                                      "2.1")
check("status attribute is confirmed",  root["status"],                                       "confirmed")
check("currency attribute is AUD",      root["currency"],                                     "AUD")

section("XML — Customer")

check("OrderId value",                  doc.at_css("OrderId").text,                           "PO-20260507-001")
check("Customer id attribute",          doc.at_css("Customer")["id"],                         "C-991")
check("Customer tier attribute",        doc.at_css("Customer")["tier"],                       "gold")
check("Customer full name",             doc.at_css("Customer FullName").text,                 "Jane Andersen")
check("Customer email",                 doc.at_css("Customer Email").text,                    "jane@example.com")
check("Phone country code attribute",   doc.at_css("Phone")["countryCode"],                   "+61")
check("Billing address city",           doc.at_css("Address[type='billing'] City").text,      "Sydney")
check("Billing address postcode",       doc.at_css("Address PostCode").text,                  "2000")

section("XML — Shipment")

check("Shipment method attribute",      doc.at_css("Shipment")["method"],                     "express")
check("Tracking number",                doc.at_css("TrackingNumber").text,                    "AUS-TRK-88821")
check("Weight unit attribute",          doc.at_css("Weight")["unit"],                         "kg")
check("Weight value",                   doc.at_css("Weight").text.to_f,                       3.75)

section("XML — Line items")

items = doc.css("LineItems Item")
check("LineItems count attribute",      doc.at_css("LineItems")["count"],                     "3")
check("Number of Item elements",        items.size,                                           3)
check("First item SKU",                 items[0]["sku"],                                      "PRD-001")
check("First item description",         items[0].at_css("Description").text,                 "Wireless Keyboard")
check("First item quantity",            items[0].at_css("Quantity").text.to_i,                2)
check("First item unit price",          items[0].at_css("UnitPrice").text.to_f,               89.99)
check("First item discount percent",    items[0].at_css("Discount")["percent"],               "10")
check("Second item SKU",                items[1]["sku"],                                      "PRD-002")
check("Third item taxable attribute",   items[2]["taxable"],                                  "false")
check("Third item description",         items[2].at_css("Description").text,                 "Extended Warranty 2yr")
check("Two items are taxable",          doc.css("Item[taxable='true']").size,                 2)

section("XML — Totals")

check("SubTotal",                       doc.at_css("Totals SubTotal").text.to_f,              250.93)
check("TaxRate percent attribute",      doc.at_css("TaxRate")["percent"],                     "10")
check("GrandTotal",                     doc.at_css("Totals GrandTotal").text.to_f,            288.12)
check("ShippingCost",                   doc.at_css("ShippingCost").text.to_f,                 15.00)

section("XML — Notes")

notes = doc.css("Notes Note")
check("Two notes present",              notes.size,                                           2)
check("First note priority",            notes[0]["priority"],                                 "high")
check("High-priority note text",        notes[0].text,                                        "Fragile items — handle with care")
check("Second note priority",           notes[1]["priority"],                                 "low")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

puts "\n#{"=" * 40}"
if $failures == 0
  puts "\e[32mAll tests passed.\e[0m"
else
  puts "\e[31m#{$failures} test(s) failed.\e[0m"
  exit 1
end
