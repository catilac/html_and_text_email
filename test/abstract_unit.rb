require 'rubygems'
require 'test/unit'

gem 'mocha', '>= 0.9.5'
require 'mocha'

$:.unshift "#{File.dirname(__FILE__)}/../lib"
require 'action_mailer'
require 'action_mailer/test_case'

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true


FIXTURE_LOAD_PATH = File.join(File.dirname(__FILE__), 'fixtures')
ActionMailer::Base.template_root = FIXTURE_LOAD_PATH

class MockSMTP
  def self.deliveries
    @@deliveries
  end

  def initialize
    @@deliveries = []
  end

  def sendmail(mail, from, to)
    @@deliveries << [mail, from, to]
  end

  def start(*args)
    yield self
  end
end

class Net::SMTP
  def self.new(*args)
    MockSMTP.new
  end
end

def uses_gem(gem_name, test_name, version = '> 0')
  gem gem_name.to_s, version
  require gem_name.to_s
  yield
rescue LoadError
  $stderr.puts "Skipping #{test_name} tests. `gem install #{gem_name}` and try again."
end

def set_delivery_method(delivery_method)
  @old_delivery_method = ActionMailer::Base.delivery_method
  ActionMailer::Base.delivery_method = delivery_method
end

def restore_delivery_method
  ActionMailer::Base.delivery_method = @old_delivery_method
end