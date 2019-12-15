require 'twitter'
require 'logger'

class TweetBot

    def self.post(body, hashtag, url)
        @client ||= Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['API_KEY']
            config.consumer_secret     = ENV['API_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_SECRET']
        end

        if ENV["enviorment"].eql?("production")
            @client.update(proccess_body(body, hashtag, url))
        elsif ENV["enviorment"].eql?("development")
            p proccess_body(body, hashtag, url)
        end
    end

    private

    def self.proccess_body(body, hashtag, url)
        if body.length > 115
            "#{body[0,115]}...(略)\n #{hashtag}\n#{url}"
        else
            "#{body} #{hashtag}\n#{url}"
        end 
    end
end