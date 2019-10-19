require 'spec_helper'

RSpec.describe 'BarkMQ.publisher_config' do
  describe '#topics_arns' do
    let(:config) { BarkMQ::Config::Publisher.new }

    it { expect(config.topic_arns).to be }

    it 'should cache topics_arns' do
        expect(config.topic_arns.keys).to be_empty

        expect(Shoryuken::Client.sns).to receive(:create_topic).and_return(
            double('topic_arn', topic_arn: 'queue-name-1-arn'))
        expect(config.fetch_topic_arn('queue-name-1')).to eq('queue-name-1-arn')
        expect(config.topic_arns.keys.size).to eq(1)
    end
  end
end
