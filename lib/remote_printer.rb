require "data_store"
require "print_queue"
require "print_processor"
require "print_archive"

class RemotePrinter
  def self.find(id)
    new(id)
  end

  def self.find_by_ip(ip)
    ip_key = "ip:#{ip}"
    now = Time.now.to_i
    DataStore.redis.zremrangebyscore(ip_key, 0, now-60)
    ids = DataStore.redis.zrangebyscore(ip_key, now-60, now)
    ids.map { |id| find(id) }
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def update(params)
    attributes_to_store = params.reject { |k,_| k == :ip }.inject([]) { |a, (k,v)| a + [k.to_s,v] }
    DataStore.redis.hmset(key, *attributes_to_store) if attributes_to_store.any?
    now = Time.now.to_i
    ip_key = "ip:#{params[:ip]}"
    DataStore.redis.zadd(ip_key, now, id)
  end

  def type
    DataStore.redis.hget(key, "type")
  end

  def version
    DataStore.redis.hget(key, "version")
  end

  def width
    PrintProcessor.for(type).width
  end

  def data_to_print
    print_info = queue.pop
    if print_info
      print = archive.find(print_info["print_id"])
      if print
        data = {"width" => print.width, "height" => print.height, "pixels" => print.pixels}
        PrintProcessor.for(type).process(data)
      end
    end
  end

  def add_print(data)
    print = archive.store(data)
    queue.enqueue(print_id: print.id)
  end

  def archive_ids
    archive.ids
  end

  def all_prints
    archive.all.sort_by { |p| p.created_at }.reverse
  end

  def find_print(print_id)
    archive.find(print_id)
  end

  private

  def queue
    PrintQueue.new(id)
  end

  def archive
    PrintArchive.new(id)
  end

  def key
    "printers:#{id}"
  end
end