require "spec_helper"

handler_class = Class.new(Lita::Handler) do
  route(/^\w{3}$/, :foo)
  route(/^\w{4}$/, :blah, command: true)
  route("restricted", :restricted, restrict_to: :some_group)

  http.get "web", :web

  on :connected, :greet

  def foo(response)
    response.reply "baz"
  end

  def blah(response)
    response.reply "bongo", "wongo"
  end

  def restricted(response)
  end

  def web(request, response)
  end

  def greet(payload)
  end

  def self.name
    "Lita::Handlers::Test"
  end
end

describe handler_class, lita_handler: true do
  it { routes("foo").to(:foo) }
  it { routes_command("blah").to(:blah) }
  it { doesnt_route("blah").to(:blah) }
  it { does_not_route("blah").to(:blah) }
  it { doesnt_route_command("yo").to(:foo) }
  it { does_not_route_command("yo").to(:foo) }
  it { routes("restricted").to(:restricted) }
  it { routes_http(:get, "web").to(:web) }
  it { doesnt_route_http(:post, "web").to(:web) }
  it { routes_event(:connected).to(:greet) }
  it { doesnt_route_event(:connected).to(:web) }
  it { does_not_route_event(:connected).to(:web) }

  describe "#foo" do
    it "replies with baz" do
      send_message("foo")
      expect(replies).to eq(["baz"])
    end
  end

  describe "#blah" do
    it "replies with bongo and wongo" do
      send_command("blah")
      expect(replies).to eq(%w(bongo wongo))
    end
  end

  it "allows the sending user to be specified" do
    another_user = Lita::User.create(2, name: "Another User")
    expect(robot).to receive(:receive) do |message|
      expect(message.source.user).to eq(another_user)
    end
    send_message("foo", as: another_user)
  end
end
