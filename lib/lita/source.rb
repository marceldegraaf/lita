module Lita
  # A wrapper object representing the source of an incoming message (either the
  # user who sent it, the room they sent it from, or both). If a room is set,
  # the message is from a group chat room. If no room is set, the message is
  # assumed to be a private message, though Source objects can be explicitly
  # marked as private messages. Source objects are also used as "target" objects
  # when sending an outgoing message or performing another operation on a user
  # or a room.
  class Source
    # A flag indicating that a message was sent to the robot privately.
    # @return [Boolean] The boolean flag.
    attr_reader :private_message
    alias_method :private_message?, :private_message

    # The room the message came from or should be sent to.
    # @return [String] A string uniquely identifying the room.
    attr_reader :room

    # The user who sent the message or should receive the outgoing message.
    # @return [Lita::User] The user.
    attr_reader :user

    # @param user [Lita::User] The user who sent the message or should receive
    #   the outgoing message.
    # @param room [String] A string uniquely identifying the room the user sent
    #   the message from, or the room where a reply should go. The format of
    #   this string will differ depending on the chat service.
    # @param private_message [Boolean] A flag indicating whether or not the
    #   message was sent privately.
    def initialize(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      @user = options[:user]
      @room = options[:room]
      @private_message = options[:private_message]

      if args.size > 0
        Lita.logger.warn <<-WARNING.chomp
Passing positional arguments to Source is deprecated. \
Use Source.new(user: user, room: room, private_message: pm) instead.
WARNING
        @user = args[0] if args[0]
        @room = args[1] if args[1]
      end

      if user.nil? && room.nil?
        raise ArgumentError.new("Either a user or a room is required.")
      end

      @private_message = true if room.nil?
    end

    # Destructively marks the source as a private message, meaning an incoming
    # message was sent to the robot privately, or an outgoing message should be
    # sent to a user privately.
    # @return [void]
    def private_message!
      @private_message = true
    end
  end
end
