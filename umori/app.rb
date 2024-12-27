require 'httparty'
require 'json'
require 'nokogiri'

TARGET_URI = 'https://www.town.yuzawa.lg.jp/soshikikarasagasu/chiikiseibibu/kensetsuka/4/2/3358.html'

def remove_space_like(str)
  str.gsub(/[\s　\u00A0]/, '')
end

def parse_info(body:) # : { date: String, location: String, tenki: Hash[String, String], max: String }
  info = {}
  doc = Nokogiri::HTML.parse(body)
  base = doc.at_css('#contents-in > .free-layout-area .wysiwyg')
  base.css('h3').each do |e|
    case e.text
    when '観測日'
      info[:date] = e.next_element.text
    when '観測地'
      info[:location] = e.next_element.text
    end
  end
  base.css('p').each do |e|
    info[:max] = e.next_element.text if e.text.match(/今シーズンの最高積雪値/)
  end
  info.transform_values! { |v| remove_space_like(v) }

  info[:tenki] = {}
  base.at_css('table').search('tr').each do |row|
    c = row.search('th, td').map { |cell| cell.text.strip }
    info[:tenki][c[0].to_sym] = c[1]
  end
  info[:tenki].transform_values! { |v| remove_space_like(v) }

  info
end

def get_info
  res = HTTParty.get TARGET_URI
  parse_info(body: res.body.gsub(/\n+/, ?\s).gsub(/\s+/, ?\s))
end

def lambda_handler(event:, context:)
  # Sample pure Lambda function

  # Parameters
  # ----------
  # event: Hash, required
  #     API Gateway Lambda Proxy Input Format
  #     Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format

  # context: object, required
  #     Lambda Context runtime methods and attributes
  #     Context doc: https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html

  # Returns
  # ------
  # API Gateway Lambda Proxy Output Format: dict
  #     'statusCode' and 'body' are required
  #     # api-gateway-simple-proxy-for-lambda-output-format
  #     Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html

  # begin
  #   response = HTTParty.get('http://checkip.amazonaws.com/')
  # rescue HTTParty::Error => error
  #   puts error.inspect
  #   raise error
  # end

  info = get_info

  {
    statusCode: 200,
    body: info.to_json
  }
end
