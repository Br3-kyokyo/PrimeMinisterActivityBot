require 'nokogiri'
require 'open-uri'
require 'pry'
require 'twitter'
require 'uri'
require './env'
require 'logger'

$log = Logger.new('./log/server.log')

class DayOfPrimeMinisterCrawler
    
    JIJI_HOST = 'https://www.jiji.com'
    JIJI_LIST_PATH = '/jc/list?g=pol'
    OPT = {}
    OPT['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36'

    def excute
        current_path = get_current_path
        unless current_path.eql?(@current_path)
            $log.info("Date update detected! reset status.")
            @actions = [], @length = 0
            @current_path = current_path
        end

        @actions = get_body_array
        unless @actions.length.eql?(@length)
            $log.info("New activities Detected! activities-num:#{@actions.length - @length}")
            prev_len = @length
            @length = @actions.length
            post_twitter(@length - prev_len)
        end
    end

    private

    def post_twitter(len)
        @client ||= Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['API_KEY']
            config.consumer_secret     = ENV['API_SECRET']
            config.access_token        = ENV['ACCESS_TOKEN']
            config.access_token_secret = ENV['ACCESS_SECRET']
        end
        body = ''
        len.downto(1) do |pos|
            $log.info("post: \"#{@actions[@length - pos]}\"")
            body += "#{@actions[@length - pos]}\n"
        end

        if ENV["enviorment"].eql?("production")
            #@client.update(proccess_body(body))
        elsif ENV["enviorment"].eql?("development")
            p proccess_body(body)
        end
    end

    def proccess_body(body)
        if body.length > 115
            "#{body[0,115]}...(略)\n #首相動静\n#{JIJI_HOST}#{@current_path}"
        else
            "#{body} #首相動静\n#{JIJI_HOST}#{@current_path}"
        end 
    end

    def get_current_path
        doc = Nokogiri::HTML(open(JIJI_HOST + JIJI_LIST_PATH, OPT))
        news_list = doc.css('#Main > div.MainInner > div.ArticleListMain > ul.LinkList > li')
        news_list.each do |news|
            if news.css('a > p').text.include?('首相動静')
                return news.at('a')[:href]
            end
        end 
    end

    def get_body_array
        doc = Nokogiri::HTML(open(JIJI_HOST + JIJI_LIST_PATH, OPT))
        news_list = doc.css('#Main > div.MainInner > div.ArticleListMain > ul.LinkList > li')
        news_list.each do |news|
            if news.css('a > p').text.include?('首相動静')
                return Nokogiri::HTML(open(JIJI_HOST + news.at('a')[:href], OPT)).css('.ArticleText > p').inner_html.delete("\t\n　").gsub(/<img.*>|<!--.*?-->|<a.*?>|<\/a>/, '').split("<br>")
            end
        end
    end
end

shinzo_crawler = DayOfPrimeMinisterCrawler.new
while true
    shinzo_crawler.excute
    sleep(60 * 5)
end
