require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require_relative 'models/invoice'
require_relative 'services/xml_generator'
require_relative 'services/pdf_generator'

set :root, File.dirname(__FILE__)
set :port, 4567
set :bind, '0.0.0.0'

# UI Routes
get '/' do
  @invoices = Invoice.order(Sequel.desc(:created_at)).all
  erb :dashboard
end

post '/invoices' do
  Invoice.create(
    client_name: params[:client_name],
    currency: params[:currency],
    amount: params[:amount].to_f,
    item_count: params[:item_count].to_i,
    unit_price: params[:unit_price].to_f,
    status: 'Generated'
  )
  redirect '/'
end

# API Routes
post '/api/invoices' do
  content_type :json
  data = JSON.parse(request.body.read)
  invoice = Invoice.create(
    client_name: data['client_name'],
    currency: data['currency'] || 'AUD',
    amount: data['amount'].to_f,
    item_count: data['item_count'].to_i,
    unit_price: data['unit_price'].to_f,
    status: 'Generated'
  )
  status 201
  { id: invoice.id, status: invoice.status }.to_json
end

get '/api/invoices/:id/xml' do
  invoice = Invoice[params[:id].to_i]
  halt 404, 'Invoice not found' unless invoice
  content_type 'application/xml'
  XmlGenerator.generate(invoice)
end

get '/api/invoices/:id/pdf' do
  invoice = Invoice[params[:id].to_i]
  halt 404, 'Invoice not found' unless invoice
  content_type 'application/pdf'
  headers['Content-Disposition'] = "inline; filename=\"invoice_#{invoice.id}.pdf\""
  PdfGenerator.generate(invoice)
end
