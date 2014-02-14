require "spec_helper"

describe Lita::Robot do
  it "logs and quits if the specified adapter can't be found" do
    adapter_registry = double("adapter_registry")
    allow(Lita).to receive(:adapters).and_return(adapter_registry)
    allow(adapter_registry).to receive(:[]).and_return(nil)
    expect(Lita.logger).to receive(:fatal).with(/Unknown adapter/)
    expect { subject }.to raise_error(SystemExit)
  end

  it "triggers a loaded event after initialization" do
    expect_any_instance_of(described_class).to receive(:trigger).with(:loaded)
    subject
  end

  context "with registered handlers" do
    let(:handler1) { class_double("Lita::Handler", http_routes: [], trigger: nil) }
    let(:handler2) { class_double("Lita::Handler", http_routes: [], trigger: nil) }

    before do
      allow(Lita).to receive(:handlers).and_return([handler1, handler2])
    end

    describe "#receive" do
      it "dispatches messages to every registered handler" do
        expect(handler1).to receive(:dispatch).with(subject, "foo")
        expect(handler2).to receive(:dispatch).with(subject, "foo")
        subject.receive("foo")
      end
    end

    describe "#trigger" do
      it "triggers the supplied event on all registered handlers" do
        expect(handler1).to receive(:trigger).with(subject, :foo, bar: "baz")
        expect(handler2).to receive(:trigger).with(subject, :foo, bar: "baz")
        subject.trigger(:foo, bar: "baz")
      end
    end
  end

  describe "#run" do
    let(:thread) { instance_double("Thread", :abort_on_exception= => true, join: nil) }

    before do
      allow_any_instance_of(Lita::Adapters::Shell).to receive(:run)
      allow_any_instance_of(Puma::Server).to receive(:run)
      allow_any_instance_of(Puma::Server).to receive(:add_tcp_listener)

      allow(Thread).to receive(:new) do |&block|
        block.call
        thread
      end
    end

    it "starts the adapter" do
      expect_any_instance_of(Lita::Adapters::Shell).to receive(:run)
      subject.run
    end

    it "starts the web server" do
      expect_any_instance_of(Puma::Server).to receive(:run)
      subject.run
    end

    it "rescues interrupts and calls #shut_down" do
      allow_any_instance_of(
        Lita::Adapters::Shell
      ).to receive(:run).and_raise(Interrupt)
      expect_any_instance_of(Lita::Adapters::Shell).to receive(:shut_down)
      subject.run
    end
  end

  describe "#send_message" do
    let(:source) { instance_double("Lita::Source") }

    it "delegates to the adapter" do
      expect_any_instance_of(
        Lita::Adapters::Shell
      ).to receive(:send_messages).with(
        source, %w(foo bar)
      )
      subject.send_messages(source, "foo", "bar")
    end
  end

  describe "#set_topic" do
    let(:source) { instance_double("Lita::Source") }

    it "delegates to the adapter" do
      expect_any_instance_of(Lita::Adapters::Shell).to receive(:set_topic).with(
        source,
        "New topic"
      )
      subject.set_topic(source, "New topic")
    end
  end

  describe "#shut_down" do
    it "gracefully stops the adapter" do
      expect_any_instance_of(Lita::Adapters::Shell).to receive(:shut_down)
      subject.shut_down
    end

    it "triggers events for shut_down_started and shut_down_complete" do
      expect(subject).to receive(:trigger).with(:shut_down_started).ordered
      expect(subject).to receive(:trigger).with(:shut_down_complete).ordered
      subject.shut_down
    end
  end
end
