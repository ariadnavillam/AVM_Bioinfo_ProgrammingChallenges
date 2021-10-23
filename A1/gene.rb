class Gene
    #initialize properties for gene object based on the fields of the tsv file
    attr_accessor :Gene_ID
    attr_accessor :Gene_name
    attr_accessor :mutant_phenotype
    attr_accessor :linked_genes

    def initialize (params = {})
        gene_id = params.fetch(:Gene_ID, "X000")
            unless gene_id.match(/A[Tt]\d[Gg]\d\d\d\d\d/)
                puts "Error. Wrong gene ID #{gene_id}."
                puts 'Gene ID for Arabidopsis Thaliana have the format: /A[Tt]\d[Gg]\d\d\d\d\d/'
                exit(1)
            else 
                @Gene_ID = params.fetch(:Gene_ID, "X000")
                @Gene_name = params.fetch(:Gene_name, "nameX")
                @mutant_phenotype = params.fetch(:mutant_phenotype, "phenotype")
                @linked_genes = Array.new
            end
        
    end

    def get_name
        return @Gene_name
    end

    def is_linked(linked_gene)
        if linked_gene.is_a?(Gene)
            @linked_genes.push(linked_gene)
        else 
            puts "Error. Enter a correct Gene ID."
        end
    end

    def check_linked_genes
        unless @linked_genes.length == 0
            @linked_genes.each do |gene|
                puts "#{@Gene_name} is linked to #{gene.get_name}."
            end
        end

    end


end

