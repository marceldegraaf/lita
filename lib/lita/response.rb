module Lita
  # A wrapper object that provides the primary interface for handlers to
  # respond to incoming chat messages.
  class Response
    extend Forwardable

    # The incoming message.
    # @return [Lita::Message] The message.
    attr_accessor :message

    # The pattern the incoming message matched.
    # @return [Regexp] The pattern.
    attr_accessor :pattern

    # @!method args
    #   @see Lita::Message#args
    # @!method reply
    #   @see Lita::Message#reply
    # @!method reply_privately
    #   @see Lita::Message#reply_privately
    # @!method user
    #   @see Lita::Message#user
    def_delegators :message, :args, :reply, :reply_privately, :user, :command?

    # @param message [Lita::Message] The incoming message.
    # @param matches [Regexp] The pattern the incoming message matched.
    def initialize(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      self.message = args[0]
      self.pattern = args[1]

      if options[:matches]
        Lita.logger.warn <<-WARNING.chomp
Passing a "matches" option to Response's constructor is deprecated. \
Use Response.new(message, pattern) instead.
        WARNING
        @matches = options[:matches]
      end
    end

    # An array of matches from scanning the message against the route pattern.
    # @return [Array<String>, Array<Array<String>>] The array of matches.
    def matches
      @matches ||= message.match(pattern)
    end

    # A +MatchData+ object from running the pattern against the message body.
    # @return [MatchData] The +MatchData+.
    def match_data
      @match_data ||= pattern.match(message.body) if pattern
    end
  end
end
