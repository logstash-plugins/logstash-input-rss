# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname
require "stud/interval"
require "faraday"
require "rss"

# Run command line tools and capture the whole output as an event.
#
# Notes:
#
# * The `@source` of this event will be the command run.
# * The `@message` of this event will be the entire stdout of the command
#   as one event.
#
class LogStash::Inputs::Rss < LogStash::Inputs::Base

  config_name "rss"

  default :codec, "plain"

  # RSS/Atom feed URL
  config :url, :validate => :string, :required => true

  # Interval to run the command. Value is in seconds.
  config :interval, :validate => :number, :required => true

  public
  def register
    @logger.info("Registering RSS Input", :url => @url, :interval => @interval)
  end # def register

  public
  def run(queue)
    @run_thread = Thread.current
    while !stop?
      start = Time.now
      @logger.info? && @logger.info("Polling RSS", :url => @url)

      # Pull down the RSS feed using FTW so we can make use of future cache functions
      response = Faraday.get @url
      handle_response(response, queue)

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
        Stud.stoppable_sleep(sleeptime) { stop? }
      end
    end # loop
  end

  def handle_response(response, queue)
    body = response.body
    begin
      feed = RSS::Parser.parse(body)
      feed.items.each do |item|
        # Put each item into an event
        case feed.feed_type
        when 'rss'
          handle_rss_response(queue, item)
        when 'atom'
          handle_atom_response(queue, item)
        end
      end
    rescue RSS::MissingTagError => e
      @logger.error("Invalid RSS feed", :exception => e)
    rescue => e
      @logger.error("Unknown error while parsing the feed", :url => url, :exception => e)
    end
  end

  def stop
    Stud.stop!(@run_thread) if @run_thread
  end

  private

  def handle_atom_response(queue, item)
    if ! item.content.nil?
      content = item.content.content
    else
      content = item.summary.content
    end
    @codec.decode(content) do |event|
      event.set("Feed", @url)
      event.set("updated", item.updated.content)
      event.set("title", item.title.content)
      event.set("link", item.link.href)
      ##
      # Author is actually a recommended field, not not a mandatory 
      # one, see https://validator.w3.org/feed/docs/atom.html for details.
      ##
      event.set("author", item.author.name.content) if !item.author.nil?
      event.set("published", item.published.content) if !item.published.nil?

      decorate(event)
      queue << event
    end
  end
  def handle_rss_response(queue, item)
    @codec.decode(item.description) do |event|
      event.set("Feed",  @url)
      event.set("published", item.pubDate)
      event.set("title", item.title)
      event.set("link", item.link)
      event.set("author", item.author) if !item.author.nil?
      decorate(event)
      queue << event
    end
  end
end # class LogStash::Inputs::Exec
