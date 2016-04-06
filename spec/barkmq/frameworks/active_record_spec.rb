require 'spec_helper'

describe 'ActiveRecord model' do

  it 'includes BarkMQ::Publisher' do
    class NewArPublisher < ActiveRecord::Base
      acts_as_publisher events: :tested
    end
    expect(NewArPublisher.ancestors).to include BarkMQ::Publisher
  end

  it 'includes BarkMQ::ActsAsPublisher' do
    class NewArPublisher < ActiveRecord::Base
      acts_as_publisher events: :tested
    end
    expect(NewArPublisher.ancestors).to include BarkMQ::ActsAsPublisher
  end

end
