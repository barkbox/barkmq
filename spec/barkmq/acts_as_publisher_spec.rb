require 'spec_helper'

RSpec.describe 'BarkMQ::ActsAsPublisher' do

  describe '.acts_as_publisher' do

    before do
      BarkMQ.publisher_config do |c|
        c.env = 'test'
        c.app_name = 'barkmq'
        c.topic_names = []
      end
    end

    it 'with no options' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
      }
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      expect(BarkMQ.pub_config.topic_names).to eq(expected_topics)
    end

    it 'with single custom event string' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
        test-barkmq-new_ar_publisher-tested
      }
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher events: :tested
      end
      expect(BarkMQ.pub_config.topic_names).to eq(expected_topics)
    end

    it 'with single custom event array' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
        test-barkmq-new_ar_publisher-tested
      }
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher events: [ :tested ]
      end
      expect(BarkMQ.pub_config.topic_names).to eq(expected_topics)
    end

    it 'with single custom serializer' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
      }
      class TestSerializer
      end
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher serializer: TestSerializer
      end
      expect(BarkMQ.pub_config.topic_names).to eq(expected_topics)
      expect(NewArPublisher.message_serializer).to eq(TestSerializer)
    end

  end

  describe '.after_create_publish' do
    
  end
end
