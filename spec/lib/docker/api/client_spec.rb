require "spec_helper"
require "docker/api/client"

describe "Docker::Api::Client" do
  let(:client) { Docker::Api::Client.new("http://127.0.0.1:4243") }

  it { client.uri.should be_kind_of(String) }

  describe "#initialize" do
    it "should strip trailing slashes" do
      client = Docker::Api::Client.new("http://127.0.0.1:4243/")
      client.uri.should end_with("4243")
    end
  end

  describe "#containers" do
    subject(:containers) { client.containers }

    it { should be_kind_of(Array) }
    it { should_not be_empty }
    it { subject.count.should eq(16) }

    describe "#first container" do
      subject(:first) { containers.first }
      it { should be_kind_of(Docker::ContainerSummary) }
      it { subject.id.should eq("e887f1f55dfbf222e5da4f9b2fa0e54138611c505d9297a3882d16424876ae02") }
      it { subject.image.should eq("a5a2dbf810b0") }
      it { subject.command.should start_with("/bin/sh -c /usr/sbin/sshd") }
      it { subject.created_at.to_i.should eq(1371420528) }
    end
  end

  describe "#get_container" do
    let(:id) { "f92e4539084c910627e094ef73315e5ebf84ee30d620f7772e0a02f9cc18f51b" }

    subject(:container) { client.get_container(id) }

    it { should_not be_nil }
    it { subject.id.should eq(id) }
    it { subject.created_at.should eq(Time.parse("2013-06-16T21:31:48.442931Z")) }

    it { subject.image.should eq("0e709ac34e3e4cb85dd8b460e4a633ff85d4f452c97a7aefbdae6987058c54e4") }
    it { subject.network_settings.should be_kind_of(Hash) }
    it { subject.ip.should eq("172.16.42.184") }
    it { subject.pid.should eq(23917) }
    it { subject.started_at.to_i.should eq(1371418308) }

    describe "container with env" do
      subject(:container) { client.get_container("50c392ff22ca5c6db69d3854d62d3cc0b4390c6e10dbfce47f11952502b6f0fd") }

      describe "#env" do
        subject(:env) { container.env }
        it { should be_kind_of(Hash) }
        it { subject["RAILS_ENV"].should eq("test") }

        it { Docker::Container.new("Id" => "test").env.should eq({}) }
      end
    end
  end

  describe "#full_images" do
    subject(:images) { client.full_images }
    it { should be_kind_of(Array) }

    describe "first image" do
      subject(:first) { images.select { |i| i.id == "2c062819c73cad52ff4034234e247d90081ccbf83a04ac53d51c914d309357bb" }.first }
      it { should be_kind_of(Docker::Image) }
      it { subject.tags.should eq(["dockyard:php"]) }
    end
  end

  describe "#images" do
    subject(:images) { client.images }

    it { should be_kind_of(Array) }
    it { subject.count.should eq(56) }

    describe "first image" do
      subject(:image) { images.first }
      it { should_not be_nil }
      it { subject.id.should eq("7945def4cc6b125e672858a54f44c44e308366ca9124f9967466b7665517ee2b") }
      it { subject.created_at.to_i.should eq(1371398134) }
      it { subject.tags.should eq(%w(dockyard:ruby)) }
    end

    describe "image without tags" do
      subject(:image) { images.select { |img| img.id == "518095220f3bb80d46eaaed9c4428790ab9006de77d4d8bc5df113833c69ef4a" }.first }
      it { should_not be_nil }
      it { subject.tags.should be_empty }
    end

    describe "ubuntu 12.10" do
      subject(:image) do
        images.select do |image|
          image.tags.include?("ubuntu:12.04")
        end.first
      end
      it { should_not be_nil }
      it { subject.tags.should be_kind_of(Array) }
    end
  end

  describe "for an image" do
    let(:id) { "a5f072706ebe6b234f087da1050796ebbefa5499e803a705e3974ebaff3181f7" }
    describe "#get_image" do
      subject(:image) { client.get_image(id) }
      it { subject.should_not be_nil }
      it { subject.id.should eq(id) }
      it { subject.parent.should eq("bd52d2f0fc9461c533a782a2cd46f7c358e9f393302047b6947aba17921b8fc2") }
      it { subject.created_at.should eq(Time.parse("2013-06-16T15:55:23.133522000Z")) }
      it { subject.container.should eq("963c3b6542f5d27d28599c3020ee801f2c5f6ba6e7b51f39b69437c6044294e5") }
    end

    describe "#get_image_history" do
      subject(:history) { client.get_image_history(id) }

      it { should_not be_nil }

      describe "#run_list" do
        subject(:run_list) { history.run_list }
        it { should be_kind_of(Array) }
        it { subject.first.should be_kind_of(Docker::ImageHistory::Item) }

        describe "first item" do
          subject(:run_list_item) { run_list.first }
          it { should_not be_nil }
          it { subject.id.should eq("a5f072706ebe") }
          it { subject.created_at.to_i.should eq(1371398123) }
          it { subject.created_by.should eq("/bin/sh -c cd /tmp/redis-2.6.13 && make install") }
        end
      end
    end

    describe "#images_tree" do
      subject(:images_tree) { client.images_tree }
      it { should_not be_nil }
      it { should be_kind_of(Docker::ImagesTree) }

      describe "parent_nodes" do
        subject(:parent_nodes) { images_tree.parent_nodes }
        it { should be_kind_of(Array) }
        it { subject.count.should eq(1) }
      end

      describe "leave_nodes" do
        subject(:leave_nodes) { images_tree.leave_nodes }
        it { subject.count.should eq(9) }
        it { subject.first.should be_kind_of(Docker::Image) }
      end
    end
  end
end

