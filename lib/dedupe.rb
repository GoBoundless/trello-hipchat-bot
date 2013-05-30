class Dedupe
  def initialize(max = 1000, seen = [])
    @max = max
    @seen = seen
  end
  def new? (val)
    crc = Zlib::crc32(val)
    if @seen.index crc
      ret = false
    else
      ret = true
      @seen << crc
    end
    @seen = @seen.pop(@max)
    return ret
  end
end
