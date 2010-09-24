# Unless you want to work hard, this just puts all our vendor libraries
# on the list of included libraries. *WILL* get confused by multiple
# versions being in the same tree.

module VendorInclude
    GEMDIR=File.dirname(__FILE__) + '/../../..'

    exclude = %w[]

    didit={}
    Dir.glob("#{GEMDIR}/*/lib").each do |d| 
        name= /([^\/]*)\/lib/.match(d)[1] 
        next if exclude.include?(name)

        (base,version) = /^(.*)(\.git|-(?:\d+\.?)+)$/.match(name)[1..2]
        if didit[base]
            raise Exception,"More than one version of #{base} in path (#{version} and #{didit[base]}). Exclude things in #{__FILE__} or clean up your submodules"
        else
            $:.unshift(d)
            didit[base] = version 
        end
    end
end
