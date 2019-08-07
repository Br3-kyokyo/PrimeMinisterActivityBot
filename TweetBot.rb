require 'twitter'
require './env'
require 'logger'

class TweetBot
    
    def self.post(body)
        @client ||= Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['API_KEY']
            config.consumer_secret     = ENV['API_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_SECRET']
        end

        if ENV["enviorment"].eql?("production")
            @client.update(proccess_body(body))
        elsif ENV["enviorment"].eql?("development")
            p proccess_body(body)
        end
    end

    private

    def self.proccess_body(body)
        if body.length > 115
            "#{body[0,115]}...(略)\n #首相動静\n#{JIJI_HOST}#{@current_path}"
        else
            "#{body} #首相動静\n#{JIJI_HOST}#{@current_path}"
        end 
    end
end