require 'pry'
require 'httpclient'
require './env'
require './PrimeMinisterWebCrawler'

module Notifiable
    def send_line_notify(error)
        client = HTTPClient.new
        uri = URI.parse(ENV["LINE_API_URL"])
        header = {
            "Content-type" => "multipart/form-data",
            "Authorization" => "Bearer #{ENV['LINE_API_TOKEN']}"
        }
        query = {
            "message" => error.full_message(highlight: false)
        }
        res = client.post(uri, query, header) 
        puts res.body
    end
end

while true
    include Notifiable
    begin
        PrimeMinisterWebCrawler.update
    rescue => error
        send_line_notify(error)
        exit
    end
    sleep(60 * 5)
end