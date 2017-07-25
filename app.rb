require 'sinatra'
require 'pp'

@authorized_numbers = ENV['AUTHORIZED_FAX_RECIPIENTS'].split(';').map {|num| num.strip.freeze }.freeze

get '/' do
  # TODO: no homepage here, see `/status`
  redirect '/status'
end

get '/status' do
  content_type 'text/plain'

  status 200
  body 'I am online!'
end

post '/fax/receive/start' do
  reject_response = <<-EOF
  <Response>
    <Reject />
  </Response>
  EOF
  allow_response = <<-EOF
  <Response>
    <Receive method="POST" action="/fax/receive/done" mediaType="application/pdf" storeMedia="true" />
  </Response>
  EOF
  output = reject_response

  content_type 'text/xml'
  catch(:processed) do
    throw :processed unless @authorized_numbers.include? params['To']

    output = allow_response
  end
  body output
end

post '/fax/receive/done' do
  if params['ErrorCode'].to_i > 0
    logger.fatal(format('TWILIO ERROR -> (%d) %s', params['ErrorCode'], params['ErrorMessage']))
    logger.debug("FULL ERROR:\n#{params.to_h.pretty_inspect}\n")
    # We're still returning 200 so Twilio knows we got the message that there was an error
  else
    logger.info(format('RECEIVING FAX -> (Pages: %d) %s', params['NumPages'], params['FaxSid'].inspect))
  end

  status 200
  body ''
end
