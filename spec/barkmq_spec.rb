require 'spec_helper'

describe BarkMQ, type: :model do
  subject { described_class }

  shared_examples_for 'a configuration method' do |method|
    it 'returns a configuration object' do
      expect(subject.send(method)).to be_a BarkMQ::Config::Shared
    end

    it 'always returns the same object' do
      expect(subject.send(method)).to be subject.send(method)
    end

    it 'accepts a block' do
      expect {
        subject.send(method) { |c| c.app_name = 'foo' }
      }.to change { subject.send(method).app_name }.to('foo')
    end
  end

  describe '.subscriber_config' do
    it_behaves_like 'a configuration method', :subscriber_config
  end

  describe '.publisher_config' do
    it_behaves_like 'a configuration method', :publisher_config
  end

  describe '.publish' do
  end

end
