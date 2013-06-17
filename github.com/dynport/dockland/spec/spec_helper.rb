#!/usr/bin/env ruby

require "vcr"
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end
require "webmock/rspec"

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true

  c.around(:each) do |example|
    # new_episodes
    VCR.use_cassette("docker", record: :new_episodes) do
      example.run
    end
  end
end

require "docker/api/client"

require "pathname"
FIXTURES_PATH = Pathname.new(File.expand_path("../fixtures", __FILE__))
