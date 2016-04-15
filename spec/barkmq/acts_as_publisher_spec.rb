require 'spec_helper'

RSpec.describe BarkMQ::ActsAsPublisher do

  before do
    BarkMQ.publisher_config do |c|
      c.logger = Logger.new('/tmp/blank.log')
    end
  end

  describe '.acts_as_publisher' do

    before do
      BarkMQ.publisher_config do |c|
        c.topic_namespace = 'test-barkmq'
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

    it 'with single after_publish' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
        test-barkmq-new_ar_publisher-tested
      }
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher

        after_publish :publish_tested, topic: 'new_ar_publisher-tested'
      end
      expect(BarkMQ.pub_config.topic_names).to eq(expected_topics)
    end

    it 'with multiple after_publish' do
      expected_topics = %W{
        test-barkmq-new_ar_publisher-created
        test-barkmq-new_ar_publisher-updated
        test-barkmq-new_ar_publisher-destroyed
        test-barkmq-new_ar_publisher-tested
        test-barkmq-new_ar_publisher-reviewed
      }
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher

        after_publish :publish_tested, topic: 'new_ar_publisher-tested'
        after_publish :publish_reviewed, topic: 'new_ar_publisher-reviewed'
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

    it 'calls after_create_publish and run_publish_callbacks' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.new
      expect(@publisher_record).to receive(:after_create_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:run_publish_callbacks).with(:after_publish_on_create)
      @publisher_record.save!
    end

  end

  describe '.after_update_publish' do

    it 'calls after_update_publish and run_publish_callbacks' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.create!
      expect(@publisher_record).to receive(:after_update_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:run_publish_callbacks).with(:after_publish_on_update)
      @publisher_record.event = 'update'
      @publisher_record.save!
    end

  end

  describe '.after_destroy_publish' do

    it 'calls after_destroy_publish and run_publish_callbacks' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher_record = NewArPublisher.create!
      expect(@publisher_record).to receive(:after_destroy_publish).and_call_original
      expect(@publisher_record).to receive(:publish_to_sns)
      expect(@publisher_record).to receive(:run_publish_callbacks).with(:after_publish_on_destroy)
      @publisher_record.destroy
    end

  end

  describe '.after_publish' do
    it 'calls error handler on error' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher

        after_publish :test_method, error: :test_method_error

        def test_method
          raise 'test error'
        end

        def test_method_error error
        end
      end
      @publisher_record = NewArPublisher.new
      expect(@publisher_record).to receive(:test_method_error).with(RuntimeError)
      @publisher_record.save
    end

    it 'calls complete handler on success' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher

        after_publish :test_method, complete: :test_method_complete

        def test_method
        end

        def test_method_complete
        end
      end
      @publisher_record = NewArPublisher.new
      expect(@publisher_record).to receive(:test_method_complete)
      @publisher_record.save
    end

    it 'calls complete handler on error' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher

        after_publish :test_method, complete: :test_method_complete

        def test_method
          raise 'test error'
        end

        def test_method_complete
        end
      end
      @publisher_record = NewArPublisher.new
      expect(@publisher_record).to receive(:test_method_complete)
      @publisher_record.save
    end
  end
end
