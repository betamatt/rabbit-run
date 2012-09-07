require "amqp"

command = "echo blah blah blah"

EM.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."

  channel  = AMQP::Channel.new(connection)
  
  exchange = channel.direct("")

  response_queue = channel.queue '', :exclusive => true do |queue, declare_ok|
    puts "Response expected on #{queue.name}"

    queue.subscribe(:ack => true) do |message|
      puts "RECV: #{message}"
    end

    exchange.publish command, :routing_key => "runner", :reply_to => response_queue.name, :immediate => true
  end  
end