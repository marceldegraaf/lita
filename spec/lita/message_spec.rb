require "spec_helper"

describe Lita::Message do
  let(:robot) do
    instance_double("Lita::Robot", name: "Lita", mention_name: "LitaBot", alias: ".")
  end

  subject do
    described_class.new(robot, "Hello", "Carl")
  end

  it "has a body" do
    expect(subject.body).to eq("Hello")
  end

  it "has a source" do
    expect(subject.source).to eq("Carl")
  end

  describe "#args" do
    it "returns an array of the 2nd through nth word in the message" do
      subject = described_class.new(robot, "args foo bar", "Carl")
      expect(subject.args).to eq(%w(foo bar))
    end

    it "escapes messages that have mismatched quotes" do
      subject = described_class.new(robot, "args it's working", "Carl")
      expect(subject.args).to eq(%w(it's working))
    end
  end

  describe "#command!" do
    it "marks a message as a command" do
      subject.command!
      expect(subject).to be_a_command
    end
  end

  describe "#command?" do
    it "is true when the message is addressed to the Robot" do
      subject = described_class.new(
        robot,
        "#{robot.mention_name}: hello",
        "Carl"
      )
      expect(subject).to be_a_command
    end

    it "is true when the Robot's name is capitalized differently" do
      subject = described_class.new(
        robot,
        "#{robot.mention_name.upcase}: hello",
        "Carl"
      )
      expect(subject).to be_a_command
    end

    it "is true when the Robot's alias is used" do
      subject = described_class.new(
        robot,
        "#{robot.alias}hello",
        "Carl"
      )
      expect(subject).to be_a_command
    end

    it "is false when the message is not addressed to the Robot" do
      expect(subject).not_to be_a_command
    end
  end

  describe "#user" do
    it "delegates to #source" do
      expect(subject.source).to receive(:user)
      subject.user
    end
  end

  describe "#reply" do
    it "sends strings back to the source through the robot" do
      expect(robot).to receive(:send_messages).with("Carl", "foo", "bar")
      subject.reply("foo", "bar")
    end
  end

  describe "#reply_privately" do
    it "sends strings directly to the source user" do
      subject = described_class.new(
        robot,
        "Hello",
        Lita::Source.new(user: "Carl", room: "#room")
      )
      expect(robot).to receive(:send_messages) do |source, *strings|
        expect(source).to be_a_private_message
        expect(strings).to eq(%w(foo bar))
      end
      subject.reply_privately("foo", "bar")
    end
  end
end
