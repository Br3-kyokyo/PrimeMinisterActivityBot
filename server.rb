require 'nokogiri'
require 'open-uri'
require 'pry'
require 'twitter'
require 'uri'
require './env'

class DayOfPrimeMinisterCrawler
    
    JIJI_HOST = 'https://www.jiji.com'
    JIJI_LIST_PATH = '/jc/list?g=pol'

    def excute
        unless get_current_path.eql?(@current_path)
            @actions = [], @length = 0
            @current_path = get_current_path
        end

        @actions = get_body_array
        unless @actions.length.eql?(@length)
            @length = @actions.length
            post_twitter
        end
    end

    private

    def post_twitter
        @client ||= Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['API_KEY']
            config.consumer_secret     = ENV['API_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_SECRET']
        end
        @client.update("#{@actions[@length-1]} #首相動静\n#{JIJI_HOST}#{@current_path}")
    end

    def get_current_path
        doc = Nokogiri::HTML(open(JIJI_HOST + JIJI_LIST_PATH))
        news_list = doc.css('#Main > div.MainInner > div.ArticleListMain > ul.LinkList > li')
        news_list.each do |news|
            if news.css('a > p').text.include?('首相動静')
                return news.at('a')[:href]
            end
        end 
    end

    def get_body_array
        doc = Nokogiri::HTML(open(JIJI_HOST + JIJI_LIST_PATH))
        news_list = doc.css('#Main > div.MainInner > div.ArticleListMain > ul.LinkList > li')
        news_list.each do |news|
            if news.css('a > p').text.include?('首相動静')
                return Nokogiri::HTML(open(JIJI_HOST + news.at('a')[:href])).css('.ArticleText > p').inner_html.delete("\t\n　").gsub(/<img.*>/, '').split("<br>")
            end
        end
    end
end

shinzo_crawler = DayOfPrimeMinisterCrawler.new
while true
    shinzo_crawler.excute
    sleep(60 * 5)
end
