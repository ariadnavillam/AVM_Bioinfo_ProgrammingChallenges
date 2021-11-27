class InteractionNetwork
    #object to store the genes that form a network
    attr_accessor :Interactors

    def initialize(params) 
        @Interactors = params.fetch(:int_array) 
    end

    def get_interactors_array
        return @Interactors #get the array of interacting genes
    end

    def get_interactors_name(gene_information) #function to print the ids of the genes with the names
        out = Array.new
        @Interactors.each do |id|
            if gene_information.key?(id) && gene_information[id].nil? == FALSE && gene_information[id].get_name.nil? == FALSE
                #check if the gene is in the hash an di it has a valid name
                out.append(id + " ("+ gene_information[id].get_name + ")" )
            else
                out.append(id)
            end
        end
        return out
    end

    def get_network_size
        return @Interactors.length
    end
    
end

class AnnotatedNetwork < InteractionNetwork
    #annotate the network with 1 kegg pathway and 5 go terms
    attr_accessor :KEGG
    attr_accessor :GO

    def initialize (params = {})
        super(params)
        @KEGG = params.fetch(:KEGG, "X000")
        @GO = params.fetch(:GO, "X000")     
        
    end 
    
    def  print_interactors
        return @Interactors.join(", ") 
    end

    def get_kegg
        return @KEGG
    end
    def get_go 
        return @GO 
    end
end