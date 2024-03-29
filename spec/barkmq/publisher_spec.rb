require 'spec_helper'

RSpec.describe BarkMQ::Publisher do

  before do
    BarkMQ.publisher_config do |c|
      c.topic_namespace = 'test-barkmq'
    end
  end

  describe '.model_name' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher
      end
      @publisher = NewPublisher.new
      expect(@publisher.model_name).to eq(nil)
    end

    it 'ActiveRecord with no options' do
      class NewArPublisher < ActiveRecord::Base
      end
      @publisher = NewArPublisher.new
      expect(@publisher.model_name.param_key).to eq('new_ar_publisher')
    end
  end

  describe '.topic' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher
      end
      @publisher = NewPublisher.new
      expect(@publisher.full_topic('created')).to eq('test-barkmq-created')
    end

    it 'ActiveRecord with no options' do
      class NewArPublisher < ActiveRecord::Base
      end
      @publisher = NewArPublisher.new
      expect(@publisher.publish_topics[:create]).to eq('new_ar_publisher-created')
      expect(@publisher.full_topic(@publisher.publish_topics[:create])).to eq('test-barkmq-new_ar_publisher-created')
    end
  end

  describe '.publish_to_sns' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher

        def serializable_hash
          { id: 1, message: 'test' }
        end
      end
      @publisher = NewPublisher.new
      expect(BarkMQ).to receive(:publish).with('test-barkmq-tested', { id: 1, message: 'test' }.to_json, { sync: true })
      @publisher.publish_to_sns('tested')
    end
  end

end
