require './PrimeMinisterWebCrawler'

while true
    PrimeMinisterWebCrawler.update
    sleep(60 * 5)
end