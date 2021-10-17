class Gene
    #initialize properties for gene object based on the fields of the tsv file
    attr_accessor :Gene_ID
    attr_accessor :Gene_name
    attr_accessor :mutant_phenotype
    attr_accessor :linked_genes

    def initialize (params = {})
        gene_id = params.fetch(:Gene_ID, "X000")
            unless gene_id.match(/A[Tt]\d[Gg]\d\d\d\d\d/)
                puts "Error. Wrong gene ID #{gene_id} in gene information file"
                puts 'Gene ID for Arabidopsis Thaliana have the format: /A[Tt]\d[Gg]\d\d\d\d\d/'
                exit(1)
            else 
                @Gene_ID = params.fetch(:Gene_ID, "X000")
                @Gene_name = params.fetch(:Gene_name, "X000")
                @mutant_phenotype = params.fetch(:mutant_phenotype, "X000")
                @linked_genes = Array.new
            end
        
    end

    def get_name
        return @Gene_name
    end

    def is_linked(linked_gene)
        if linked_gene.is_a?(Gene)
            @linked_genes.push(linked_gene)
            puts "#{@Gene_name} linked to #{linked_gene.get_name}."
        else 
            puts "Error. Enter a correct Gene ID."
        end
    end

end

