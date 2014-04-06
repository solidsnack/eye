require 'celluloid/io'
require 'celluloid/autostart'

class Eye::Server
  include Celluloid::IO

  attr_reader :socket_path, :server

  def initialize(socket_path)
    @socket_path = socket_path
    @server = begin
      UNIXServer.open(socket_path)
    rescue Errno::EADDRINUSE
      unlink_socket_file
      UNIXServer.open(socket_path)
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    text = socket.read

    begin
      h = Marshal.load(text)
      cmd = h[:cmd]
      args = h[:args]
      wait = h[:wait]
    rescue => ex
      error "Failed to read from socket: #{ex.message}"
      return
    end

    response = command(cmd, args, wait)
    socket.write(Marshal.dump(response))

  rescue Errno::EPIPE
    # client timeouted
    # do nothing

  ensure
    socket.close
  end

  def command(cmd, args, wait = false)
    condition = Celluloid::Condition.new
    res = Eye::Control.command(cmd, args, condition)
    wait ? condition.wait : res
  end

  def unlink_socket_file
    File.delete(@socket_path) if @socket_path
  rescue
  end

  finalizer :close_socket

  def close_socket
    @server.close if @server
    unlink_socket_file
  end

end