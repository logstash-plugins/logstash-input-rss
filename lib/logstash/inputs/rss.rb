# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Run command line tools and capture the whole output as an event.
#
# Notes:
#
# * The '@source' of this event will be the command run.
# * The '@message' of this event will be the entire stdout of the command
#   as one event.
#
class LogStash::Inputs::Rss < LogStash::Inputs::Base

  config_name "rss"
  milestone 2

  default :codec, "plain"

  # RSS/Atom feed URL
  config :url, :validate => :string, :required => true

  # Interval to run the command. Value is in seconds.
  config :interval, :validate => :number, :required => true

  public
  def register
    require "ftw"
    @logger.info("Registering RSS Input", :url => @url, :interval => @interval)
    @agent = FTW::Agent.new
  end # def register

  public
  def run(queue)
    loop do
      start = Time.now
      @logger.info? && @logger.info("Polling RSS", :url => @url)

      # Pull down the RSS feed using FTW so we can make use of future cache functions
      response = @agent.get!(@url)
      body = ""
      response.read_body { |c| body << c }
      # Parse the RSS feed

      @logger.debug("Body", :body => body)
      @codec.decode(body) do |event|
        decorate(event)
        event["Feed"] = @url
        queue << event
      end
      duration = Time.now - start
      @logger.info? && @logger.info("Command completed", :command => @command,
                                    :duration => duration)

      # Sleep for the remainder of the interval, or 0 if the duration ran
      # longer than the interval.
      sleeptime = [0, @interval - duration].max
      if sleeptime == 0
        @logger.warn("Execution ran longer than the interval. Skipping sleep.",
                     :command => @command, :duration => duration,
                     :interval => @interval)
      else
        sleep(sleeptime)
      end
    end # loop
  end # def run
end # class LogStash::Inputs::Exec
