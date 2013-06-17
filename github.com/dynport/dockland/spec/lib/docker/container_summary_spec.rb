require "spec_helper"

describe "Docker::ContainerSummary" do
  subject(:container) { Docker::ContainerSummary.new("Id" => "409d26af7dc2a1bc9d802d966a8b10fe885c97fcbeccbe62f136c5a168887b88") }

  it { should_not be_nil }
end

