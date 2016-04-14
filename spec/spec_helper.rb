$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'celluloid'
require 'barkmq'
require 'circuitry/testing'
require 'redis'
require 'coveralls'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                        database: File.dirname(__FILE__) + "/db.sqlite3")
load File.dirname(__FILE__) + '/support/schema.rb'

Coveralls.wear!
