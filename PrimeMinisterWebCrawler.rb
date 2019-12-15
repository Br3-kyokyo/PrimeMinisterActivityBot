require 'nokogiri'
require 'open-uri'
require 'uri'
require 'logger'
require 'time'
require './TweetBot.rb'
require 'yaml'

$log = Logger.new('./log/server.log')

class PrimeMinisterWebCrawler

    data = open('config.yml', 'r') { |f| YAML.load(f) }
    
    JIJI_HOST = data["TARGET_URL"]
    JIJI_LIST_PATH = data["TARGET_LIST_PATH"] 
    OPT = {} 
    OPT['User-Agent'] = data["USER_AGENT"]

    def self.update
        update_article_path
        update_activities
        update_tweet unless @activities.length.eql?(@row_count)
    end

    private

    def self.update_tweet
        $log.info("New activities Detected! activities-num:#{@activities.length - @row_count}")
            
        prev_len = @row_count
        @row_count = @activities.length

        body = ''
        (@row_count - prev_len).downto(1) do |pos|
            $log.info("post: \"#{@activities[@row_count - pos]}\"")
            body += "#{@activities[@row_count - pos]}\n"
        end

        TweetBot.post(body, '#首相動静', "#{JIJI_HOST}#{@current_path}") unless is_first
    end

    def self.update_activities
        @activities = get_activities
    end

    def self.update_article_path
        current_article_path = get_current_article_path
        unless current_article_path.eql?(@today_article_path)
            $log.info("Date update detected! reset status.")
            @activities = [], @row_count = 0
            @today_article_path = current_article_path
        end
    end

    def self.get_current_article_path
        doc = Nokogiri::HTML(open(JIJI_HOST + JIJI_LIST_PATH, OPT))
        news_list = doc.css('#Main > div.MainInner > div.ArticleListMain > ul.LinkList > li > a')
        pm_news_list = news_list.each_with_object([]) {|news, h| h << news if news.at('p').text.include?('首相動静') }
        latest_pm_news = pm_news_list.max_by {|pm_news| Time.parse(pm_news.at('span').text) }
        latest_pm_news[:href]
    end

    def self.get_activities
        Nokogiri::HTML(open(JIJI_HOST + @today_article_path, OPT)).css('.ArticleText > p').inner_html.delete("\t\n　").gsub(/<img.*>|<!--.*?-->|<a.*?>|<\/a>/, '').split("<br>")
    end

    def self.is_first
        @_not_first ? false : @_not_first = true
    end
end