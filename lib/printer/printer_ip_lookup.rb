require "printer/data_store"
require "printer/remote_printer"

class Printer::PrinterIPLookup
  def self.update(printer, ip)
    if ip
      now = Time.now.to_i
      Printer::DataStore.redis.zadd("ip:#{ip}", now, printer.id)
    end
  end

  def self.find_printer(ip)
    if ip == "127.0.0.1"
      if local_printer_ip = find_local_printer_ip
        ip_key = "ip:#{local_printer_ip}"
      else
        return []
      end
    else
      ip_key = "ip:#{ip}"
    end
    now = Time.now.to_i
    Printer::DataStore.redis.zremrangebyscore(ip_key, 0, now-60)
    ids = Printer::DataStore.redis.zrangebyscore(ip_key, now-60, now) || []
    ids.map { |id| Printer::RemotePrinter.find(id) }
  end

  def self.find_local_printer_ip
    possible_keys = Printer::DataStore.redis.keys("ip:192.168.*") +
                    Printer::DataStore.redis.keys("ip:10.*")
    possible_keys.any? ? possible_keys.first.split(":").last : nil
  end
end
