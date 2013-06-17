require "spec_helper"
require "docker/images_tree"

describe "Docker::ImagesTree" do
  let(:client) { Docker::Api::Client.new("http://127.0.0.1:4243") }
  subject(:tree) { client.images_tree  }
  it { should_not be_nil }

  describe "#to_digraph" do
    subject(:to_digraph) { tree.to_digraph("http://some.host") }
    it { should be_kind_of(String) }
    it { should start_with("digraph docker {") }
    it { should end_with("}") }
    it { should include(%("0e2b3d62" -> "34ef04ed")) }
    it { should include(%(base -> "8dbd9e39" [style=invis];)) }
    it { should include(%(base [style=invisible])) }
  end

  describe "serialize_image" do
    subject(:image) { client.full_images.at(16) }

    it { subject.class }

    subject(:arr) { tree.serialize_image(image, "test") }
    it { should be_kind_of(Array) }

    describe "first image" do
      subject(:line) { arr.join(" ") }
      it { should include("label=\"7651a18e\"") }
      it { should include("\"3c2091c7\" -> \"7651a18e\"") }
    end
  end
end

