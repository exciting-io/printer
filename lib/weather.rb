require "open-uri"
require "json"

class Weather
  class << self
    attr_accessor :api_key
  end

  def initialize
    url = "http://api.wunderground.com/api/#{Weather.api_key}/hourly/q/zmw:00000.1.03772.json"
    @data = JSON.parse(open(url).read)
    @hours = @data["hourly_forecast"].inject({}) do |h, t| 
      time = Time.at(t["FCTTIME"]["epoch"].to_i)
      if time >= start_time && time <= end_time
        h.merge({time => {
          temp: t["temp"]["metric"],
          condition: t["icon"]
        }})
      else
        h
      end
    end
  end

  def daily_report
    {day_for: day_for,
     now: now,
     morning: summary_for_hours(8..11),
     lunch: summary_for_hours(12..14),
     afternoon: summary_for_hours(15..18),
     evening: summary_for_hours(19..23)}
  end

  private

  def now
    {temperature: @data["hourly_forecast"][0]["temp"]["metric"]}
  end

  def day_for
    if start_time < Time.now
      "today"
    else
      "tomorrow"
    end
  end

  def start_time
    @start_time ||= if Time.now.hour > 15
      (Date.today + 1).to_time
    else
      Date.today.to_time
    end
  end

  def end_time
    @end_time ||= (start_time + (60*60*24)-1)
  end

  def weather_for_hours(range)
    @hours.select { |t| range.include?(t.hour) }
  end

  def average_temp(hours)
    hours.inject(0) { |a, (t,f)| a + f[:temp].to_i } / hours.length
  end

  def average_symbol(hours)
    counts = hours.map { |t,f| f[:condition] }.inject({}) { |h,c| h[c] ||= 0; h[c] += 1; h }.invert
    counts[counts.keys.max]
  end

  def summary_for_hours(range)
    hours = weather_for_hours(range)
    temp = average_temp(hours)
    symbol = average_symbol(hours)
    {temperature: temp, symbol: symbol}
  end
end