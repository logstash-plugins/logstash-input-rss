# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/rss"

describe LogStash::Inputs::Rss do
  describe "stopping" do
    let(:config) { {"url" => "localhost", "interval" => 10} }
    before do
      allow(Faraday).to receive(:get)
      allow(subject).to receive(:handle_response)
    end
    it_behaves_like "an interruptible input plugin"
  end
end