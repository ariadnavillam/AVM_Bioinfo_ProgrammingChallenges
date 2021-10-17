class HybridCross
    attr_accessor :Parent1
    attr_accessor :Parent1
    attr_accessor :F2_Wild
    attr_accessor :F2_P1
    attr_accessor :F2_P1P2
    attr_accessor :F2_P2

    def initialize (params = {})
        @Parent1 = params.fetch(:Parent1, "X000")
        @Parent2 = params.fetch(:Parent2, "X000")
        @F2_Wild = params.fetch(:F2_Wild, "X000")
        @F2_P1 = params.fetch(:F2_P1, "X000")
        @F2_P2 = params.fetch(:F2_P2, "X000")
        @F2_P1P2 = params.fetch(:F2_P1P2, "X000")
    end

end


class Gene
    attr_accessor :Gene_ID
    attr_accessor :Gene_name
    attr_accessor :mutant_phenotype


    def initialize (params = {})
        @Gene_ID = params.fetch(:Gene_ID, "X000")
        @Gene_name = params.fetch(:Gene_name, "X000")
        @mutant_phenotype = params.fetch(:mutant_phenotype, "X000")
    end

    def print_all 
        puts @Gene_ID, @Gene_name, @mutant_phenotype
    end

end

class SeedStock
    attr_accessor :Last_Planted
    attr_accessor :Storage
    attr_accessor :Grams_Remaining


    def initialize (params = {})
        @Last_Planted = params.fetch(:Last_Planted, "X000")
        @Storage = params.fetch(:Storage, "X000")
        @Grams_Remaining = params.fetch(:Grams_Remaining, "X000")
    end

    def gene_id=(new_id)
        puts @Gene_ID, @Gene_name, @mutant_phenotype
    end


end

#parse cross_data 
path_file = "cross_data.tsv"
count = 0
field_names = Array.new
data = Array.new
if File.exist?(path_file)
    File.open(path_file).each do |line|
        column = line.strip.split("\t")
        line_hash = Hash.new
        if count == 0 then
            column.each do |field|
                field_names.push(field.intern)
            end
        else 
            i = 0 
            column.each do |value|
                line_hash[field_names[i]] = value
                i += 1
            end
            data[count-1] = HybridCross.new(line_hash)
            
        end
    
        count+=1
    end
end

# parse gene file

path_file = "gene_information.tsv"
count = 0
field_names = Array.new
data = Array.new
if File.exist?(path_file)
    File.open(path_file).each do |line|
        column = line.strip.split("\t")
        line_hash = Hash.new
        #puts line
        if count == 0 then
            column.each do |field|
                field_names.push(field.intern)
            end
        else 
            i = 0 
            column.each do |value|
                line_hash[field_names[i]] = value
                i += 1
            end
            data[count-1] = Gene.new(line_hash)
            
        end
    
        count+=1
    end
end

data.each do |item|
    item.print_all
end



