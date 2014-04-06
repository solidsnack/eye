module Eye::Controller::Commands

  # Main method, answer for the client command
  def command(cmd, args, condition)
    debug "client command: #{cmd} #{args * ', '}"
    start_at = Time.now
    cmd = cmd.to_sym
    res = execute_command(cmd, args, condition)
    GC.start
    info "client command: #{cmd} #{args * ', '} (#{Time.now - start_at}s)"
    res
  end

private

  def execute_command(cmd, args, condition)
    return exclusive{ send_command(cmd, args, condition) } if cmd == :delete
    return signal(args, condition) if cmd == :signal

    if [:start, :stop, :restart, :unmonitor, :monitor, :break_chain].include?(cmd)
      return send_command(cmd, args, condition)
    end

    res = case cmd
      when :load
        load(*args)
      when :quit
        quit
      when :check
        check(*args)
      when :explain
        explain(*args)
      when :match
        match(*args)
      when :ping
        :pong
      when :logger_dev
        Eye::Logger.dev

      # object commands, for api
      when :info_data
        info_data(*args)
      when :short_data
        short_data(*args)
      when :debug_data
        debug_data(*args)
      when :history_data
        history_data(*args)

      else
        :unknown_command
    end

    condition.signal(res)
    res
  end

  def quit
    info 'Quit!'
    Eye::System.send_signal($$, :TERM)
    sleep 1
    Eye::System.send_signal($$, :KILL)
  end

end
