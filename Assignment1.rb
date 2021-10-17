require './gene'
require './hybrid_cross'
require './seed_stock'

def load_from_file(path_file)
    count = 0
    field_names = Array.new
    data = Hash.new
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

                data[line_hash[field_names[0]]] = line_hash
                
            end
        
            count+=1
        end
    
        return data

    else
        puts "Error. Could not open file #{path_file}."
    end
end

# Command line arguments error handling
if ARGV.length != 4
    puts "Wrong number of arguments."
    puts "Input: $ ruby process_database.rb  gene_information.tsv  seed_stock_data.tsv  cross_data.tsv  new_stock_file.tsv"
    exit(1)
else 
    count = 0
    ARGV.each do |argument|
        unless argument.to_s.match("\\.rb$") || argument.to_s.match("\\.tsv$")
            puts "Wrong file #{argument}."
            puts "Input: $ ruby process_database.rb  gene_information.tsv  seed_stock_data.tsv  cross_data.tsv  new_stock_file.tsv"
            exit(1)
        end 

        unless File.exist?(argument) || count == 3
            puts "Wrong file #{argument}: does not exist."
            exit(0)
        end
        
        count +=1
    end
end

#convert the hash returned by the load_from_file function into a hash of objects for:
#the cross_data file that contains hybridcross 
cross_data = load_from_file("cross_data.tsv")
cross_data.each_key do |key|
    cross_data[key] = HybridCross.new(cross_data[key])
end
#the gene_information file that contains the genes
genes_data = load_from_file("gene_information.tsv")
genes_data.each_key do |key|
    genes_data[key] = Gene.new(genes_data[key])
end
#the seed_stock_data file that contains the relation between the seeds and the genes
seedstock_data = load_from_file("seed_stock_data.tsv")
seedstock_data.each_key do |key|
    seedstock_data[key] = SeedStock.new(seedstock_data[key])
end

#plant 7 grams of each seed
seedstock_data.each_key do |seed|
    seedstock_data[seed].plant
end

# for each cross_data entry evaluate if the genes of the seeds are linked
cross_data.each_key do |key|
    parent_seeds = cross_data[key].get_parents
    gene1 = genes_data[seedstock_data[parent_seeds[0]].get_gene]
    gene2 = genes_data[seedstock_data[parent_seeds[1]].get_gene]
    chi_square = cross_data[key].test_link
    if chi_square > 7.18
        puts
        puts "Recording: #{gene1.get_name} is genetically linked with #{gene2.get_name} with chisquare score #{chi_square}."
        puts
        puts "Final Report: \n"
        gene1.is_linked(gene2)
        gene2.is_linked(gene1)
    end
end

# write new seed stock data to the file
File.open("file_new.tsv", "w") do |f| 
    count = 0
    first_line =Array.new
    seedstock_data.each_pair do |key,value| #each key and value of the seed stock hash
        if count == 0 #in the first line we need the name of each of the properties of the object as header
            seedstock_data[key].instance_variables.each do |f|
                first_line.push(f[1,f.length])
            end
            f.write(first_line.join("\t")+"\n")
        end
        f.write(value.get_properties)
        count +=1
    end 
end



