require 'prawn'

class PdfGenerator
  def self.generate(invoice)
    Prawn::Document.new do |pdf|
      pdf.text "INVOICE ##{invoice.id}", size: 24, style: :bold
      pdf.move_down 10
      pdf.text "Client: #{invoice.client_name}"
      pdf.text "Currency: #{invoice.currency}"
      pdf.move_down 10

      pdf.text "Line Items:", style: :bold
      invoice.item_count.times do |i|
        pdf.text "  Item #{i + 1}: #{invoice.currency} #{invoice.unit_price}"
      end

      pdf.move_down 10
      pdf.text "Total: #{invoice.currency} #{invoice.total}", style: :bold
      pdf.text "Status: #{invoice.status}"
      pdf.text "Generated: #{invoice.created_at}"
    end.render
  end
end
