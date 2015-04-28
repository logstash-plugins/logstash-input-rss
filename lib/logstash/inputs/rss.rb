# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

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

  # In theory, validating received RSS is a good idea.  But,
  # the internet is a messy place and sites can not be forced to
  # emit valid RSS feeds.
  config :validate_rss, :validate => :boolean,  :default => false

  public
  def register
    require "faraday"
    require "rss"
    @logger.info("Registering RSS Input", :url => @url, :interval => @interval)
  end # def register

  public
  def run(queue)
    loop do
      start = Time.now
      @logger.info? && @logger.info("Polling RSS", :url => @url)

      conn = Faraday.new() do |f|
        f.adapter Faraday.default_adapter
      end
      # Pull down the RSS feed using FTW so we can make use of future cache functions
      begin
        response = conn.get(@url)
      rescue => e
        @logger.warn("Failed to fetch RSS", :url => @url, :exception => e)
      else
        if response.status != 200
          @logger.warn("Received unexpected response", :code=>response.status)
          if response.status >= 300 and response.status < 400
            # TODO:  Unfortunately Faraday Middleware not available in logstash to
            # handle redirects,
            @logger.warn("Need to update url", :body => response.body)
          end
        else
          body = response.body
          # @logger.debug("Body", :body => body)
          # Parse the RSS feed
          begin
            feed = RSS::Parser.parse(body, do_validate = @validate_rss)
          rescue => e
            @logger.warn("Failed to parse response.", :url=> @url, :exception => e, :body => body)
          else
            feed.items.each do |item|
              # Put each item into an event
              #@logger.debug("Item", :item => item.author)
              case feed.feed_type
                when 'rss'
                  @codec.decode(item.description) do |event|
                    event["Feed"] = @url
                    event["published"] = item.pubDate
                    event["title"] = item.title
                    event["link"] = item.link
                    event["author"] = item.author
                    decorate(event)
                    queue << event
                  end
                when 'atom'
                  if ! item.content.nil?
                      content = item.content.content
                  else
                      content = item.summary.content
                  end
                  @codec.decode(content) do |event|
                    event["Feed"] = @url
                    event["updated"] = item.updated.content
                    event["title"] = item.title.content
                    event["link"] = item.link.href
                    event["author"] = item.author.name.content
                    unless item.published.nil?
                        event["published"] = item.published.content
                    end
                    decorate(event)
                    queue << event
                  end
                end
              end
          end
        end
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
