require 'socket'
require 'timeout'

class Eye::Client
  attr_reader :socket_path

  def initialize(socket_path)
    @socket_path = socket_path
  end

  def command(cmd, args, wait = false)
    pack = Marshal.dump(:cmd => cmd, :args => args, :wait => wait)
    if wait
      send_request(pack)
    else
      attempt_command(pack)
    end
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
      socket.write(pack)
      data = socket.read
      res = Marshal.load(data) rescue :corrupted_data
    end
  end

end
