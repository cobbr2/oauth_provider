
module Ez

    class Customer
        include DataMapper::Resource

        decorate :default_repository_name, :ez

        ## Properties
        property :id,                  Serial

    end

end
