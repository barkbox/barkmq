require 'spec_helper'

RSpec.describe BarkMQ::ActsAsPublisher do

  describe '.acts_as_publisher' do

    before do
      BarkMQ.publisher_config do |c|
        c.topic_prefix = 'test-barkmq'
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

  describe 'create active record model' do

    it 'calls after_create_publish and after_create_callback' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.new
      expect(@publisher_record).to receive(:after_create_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:after_create_callback)
      @publisher_record.save!
    end

  end

  describe '.after_update_publish' do

    it 'calls after_update_publish and after_update_callback' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.create!
      expect(@publisher_record).to receive(:after_update_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:after_update_callback)
      @publisher_record.event = 'update'
      @publisher_record.save!
    end

  end

  describe '.after_destroy_publish' do

    it 'calls after_destroy_publish and after_destroy_callback' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.create!
      expect(@publisher_record).to receive(:after_destroy_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:after_destroy_callback)
      @publisher_record.destroy
    end

  end
end
