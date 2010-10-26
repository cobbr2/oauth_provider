require 'fileutils'

# FIXME: Helps the cloud_crowd backend survive for the moment. Remove when that's separated
# from the package again.
class Object
    def decorate(name, value)
       # do nothing 
    end
end


module OAuthBackendHelper
  module InMemory
    def self.create
      OAuthProvider.create(:in_memory)
    end

    def self.setup; end
    def self.reset; end
  end

  module DataMapper
    def self.create
      OAuthProvider.create(:data_mapper)
    end

    def self.setup
      require 'dm-core'
      require 'dm-migrations'
      #::DataMapper.setup(:default, "sqlite3:///tmp/oauth_provider_test.sqlite3")
      ::DataMapper.setup(:default, "mysql://localhost/oauth_provider_test")
    end

    def self.reset
      create
      ::DataMapper.auto_migrate!
    end
  end

  # Harumph. Our backend doesn't test easily, since it's tied to our user models.
  # 
  # Not clear how to get those tricks implemented
  # yet, but this is a prerequisite anyway.
  module CloudCrowd
    def self.create
      OAuthProvider.create(:cloud_crowd)
    end

    def self.setup
      require 'dm-core'
      require 'dm-migrations'
      require 'dm-types'
      #::DataMapper.setup(:default, "sqlite3:///tmp/oauth_provider_test.sqlite3")
      # Fails because the rest of our ez models aren't there. Once you tie 
      # to ez_customer, life gets hard. Guess we'd need a customer-helper...
      require 'helpers/cloud_crowd_customer'
      ::DataMapper.setup(:default, "mysql://localhost/oauth_provider_test")
    end

    def self.reset
      create
      ::DataMapper.auto_migrate!
    end

    # The test user may have to be created on every call, since 
    # the reset above is called between individual test cases.
    # Memo-izing it will cause failiures :/
    def self.test_user
      test_user = Ez::Customer.first_or_create()
      return test_user
    end
  end

  module Sqlite3
    PATH = "/tmp/oauth_provider_sqlite3_test.sqlite3" unless defined?(PATH)

    def self.create
      OAuthProvider.create(:sqlite3, PATH)
    end

    def self.setup; end

    def self.reset
      FileUtils.rm(PATH) rescue nil
    end
  end

  module Mysql
    def self.create
      host      = ENV['MYSQL_HOST'] || "localhost"
      user      = ENV['MYSQL_USER'] || "root"
      password  = ENV['MYSQL_PASSWORD'] || ""
      db        = ENV['MYSQL_DB'] || "oauth_provider_test"
      port      = ENV['MYSQL_PORT'] || 3306
      OAuthProvider.create(:mysql, host, user, password, db, port)
    end

    def self.setup; end

    def self.reset
      self.create.backend.clear!
    end
  end


  def self.setup
    backend_module.setup
  end

  def self.reset
    backend_module.reset
  end

  def self.provider
    backend_module.create
  end

  def self.backend_module
    klass_name = backend_name.to_s.split('_').map {|e| e.capitalize}.join
    unless const_defined?(klass_name)
      $stderr.puts "There is no backend for #{backend_name.inspect}"
      exit!
    end
    const_get(klass_name)
  end

  def self.backend_name
    (ENV["BACKEND"] || "in_memory").to_sym
  end

  def self.user
    test_user = backend_module.respond_to?(:test_user) ? backend_module.test_user : nil
  end
end
