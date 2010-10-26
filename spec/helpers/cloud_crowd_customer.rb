
# FIXME: Helps the cloud_crowd backend survive for the moment. Remove when that's separated
# from the package again.
class Object
    def decorate(name, value)
       # do nothing 
    end
end

module Ez

    class Customer
        include DataMapper::Resource

        decorate :default_repository_name, :ez

        ## Properties
        property :id,                  Serial

    end

end
