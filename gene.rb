class Gene
    #initialize properties for gene object based on the fields of the tsv file
    attr_accessor :Gene_ID
    attr_accessor :Gene_name
    attr_accessor :Uniprot_ID

    def initialize (params = {})
        @Gene_ID = params.fetch(:Gene_ID, "X000")
        @Gene_name = params.fetch(:Gene_name, "nameX")
        @Uniprot_ID = params.fetch(:Uniprot_ID, "X000")
    end

    def get_uniprot_id
        return @Uniprot_ID
    end

    def get_all #this methos puts each of the properties of each object 
        all = Array.new
        instance_variables.map do |ivar| 
            all.push(instance_variable_get ivar)
        end
        line = all.join("\t")
        return line
    end

end