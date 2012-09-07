require 'amqp'

EM.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."

  channel  = AMQP::Channel.new(connection)

  channel.queue("runner", :auto_delete => true).subscribe(:ack => true) do |metadata, payload|
    puts "EXEC: #{payload}"
    puts "REPL: #{metadata.reply_to}"

    channel.queue("", :exclusive => true) do |input_queue|
      channel.default_exchange.publish "", :routing_key => metadata.reply_to, :reply_to => input_queue.name
      IO.popen(payload) do |io|
        input_queue.subscribe(:ack => true) do |message|
          io.put message
        end

        until io.eof?
          buffer = io.gets
          puts "OUT: #{buffer}"
          channel.default_exchange.publish buffer, :routing_key => metadata.reply_to
        end
      end
    end
  end

end
