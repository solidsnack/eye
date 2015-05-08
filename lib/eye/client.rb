require 'socket'
require 'timeout'

class Eye::Client
  attr_reader :socket_path

  def initialize(socket_path)
    @socket_path = socket_path
  end

  def command(cmd, *args)
    attempt_command(Marshal.dump([cmd, *args]))
  end

  def attempt_command(pack)
    Timeout.timeout(Eye::Local.client_timeout) do
      return send_request(pack)
    end

  rescue Timeout::Error, EOFError
    :timeouted
  end

  def send_request(pack)
    UNIXSocket.open(@socket_path) do |socket|
      puts "#{@socket_path} pack: '#{pack.unpack('H*').first}'"
      socket.write(pack)
      data = socket.read
      puts "#{@socket_path} data: '#{data.unpack('H*').first}'"
      res = Marshal.load(data) rescue :corrupted_data
      puts "#{@socket_path} res: '#{res}'"
      res
    end
  end


end
