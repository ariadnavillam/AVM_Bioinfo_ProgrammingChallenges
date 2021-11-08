require 'rest-client'  
require 'csv'
require 'json'  
require './web_functions.rb'
require './interaction_network.rb'
require './annotation.rb'
require './gene.rb'

#redirect stderr to log file

$stderr.reopen("log.txt", "w")

# Command line arguments error handling
#Correct number of arguments?

if ARGV.length >= 2 && ARGV.length <= 4
    if ARGV.length > 2 
        
        begin 
            miscore = ARGV[2].to_f
        rescue
            puts "Error. Please enter a correct miscore value."
            puts "The miscore value is between 0 and 1. Format: 0.37."
            puts "Default value = 0.45"
            exit(1)
        end
        
        if ARGV.length == 4
            print "b"
            begin 
                depth = ARGV[3].to_i
                print depth
            rescue
                puts "Error. Please enter a correct depth value."
                puts "The depth value is between 1 and 3."
                puts "1 -> direct interaction, 2 -> interaction by 1 gene, 3 -> interaction by 2 genes."
                puts "Default value = 3."
                exit(1)
            end
        else
            depth = 3
        end

    else
        print "c"
        miscore = 0.45
        depth = 3
    end

else 
    puts "Error. Wrong number of arguments."
    puts "Input: $ ruby main.rb  genes_file.txt output_file.txt [miscore-value] [depth-value]"
    exit(1)
end

unless File.exist?(ARGV[0]) 
    puts "Wrong gene file. Please enter a valid gene file."
    puts "Input: $ ruby main.rb  genes_file.txt output_file.txt [miscore_value] "
    exit(1)
end

## OUTPUT START PROGRAM

file_path = ARGV[0]
out_path = ARGV[1]
puts "File with genes: #{file_path}"
puts "Output file: #{out_path}"
puts "Intact-miscore filter: #{miscore}"
puts "Depth of search: #{depth}"
puts

#save gene names in hash
origin_genes = Hash.new
File.foreach(file_path) do |line|
    gene = line.strip
    gene = gene.sub("T","t") #to search for the genes the t must be in lower case
    origin_genes[gene] = Array.new
end

#retrieve genes that interact
puts
gene_information = Hash.new #save protid and name for each gene
origin_genes.each_key do |gene_key|
    puts "Searching for genes that interact with #{gene_key}" #since the run time is long we print a message when we change the gene
    new_genes = Array.new #array to save the genes that interact
    get_interaction_genes(gene_key, origin_genes, new_genes, gene_key, depth, miscore) #recursive function
    int_genes = Array.new
    new_genes.each do |new_gene|
        int_genes.append(new_gene[0]) unless new_gene[0] == gene_key #save genes id (index 0) except if the gene is the starting gene
        gene_information[new_gene[0]] = Gene.new({:Gene_ID => new_gene[0], :Uniprot_ID => new_gene[1], :Gene_name => new_gene[2]}) unless gene_information.key?(new_gene) 
        #save gene id, uniprot id and gene name
    end
    origin_genes[gene_key] = int_genes #save interacting genes in hash
end

# save the network only in one array
origin_genes.each_pair do |key, value|
    value.each do |int_gene|
        origin_genes[key] = origin_genes[key] + origin_genes[int_gene] #merge all interacting genes in one array, so that there isnt any gene in various networks
        origin_genes[int_gene] = [] #save the array in the previous key and delete the value for every interactor

    end
end

# create an array of all the networks
inter_network_array = Array.new
origin_genes.each_pair do |key, value|
    if value.length > 0 #if there is some interactor save the values
        array = value
        array.append(key) #append the key in case there is not already in the array
        inter_network_array.append(InteractionNetwork.new({:int_array => array.uniq})) #save unique values of each gene
    end
end
puts
puts "Annotating the networks of genes..."
#annotate the network
annotated_network_array = Array.new
inter_network_array.each do |inter_network| #for each network
    int_array = inter_network.get_interactors_array #get the interactor genes
    paths = Array.new #array to save the kegg paths associated with that network
    int_array.each do |geneid|
        record = get_kegg_record(geneid)
        paths.concat(get_kegg_path(record)) #save all kegg from all the genes
    end

    unless paths.length == 0
        freq = paths.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
        max_path = paths.max_by { |v| freq[v] }
    else
        max_path = "Not found"
    end

    #keep only the most frequent one between the genes interacting
    terms = Array.new
    int_array.each do |geneid|
        go_rec = get_go_record(gene_information[geneid].get_uniprot_id) unless gene_information[geneid].nil?
        terms.concat(get_go_terms(go_rec)) unless go_rec.nil?
    end
    freq = terms.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
    temp = freq.sort_by(&:last)
    terms = temp.last(5)
    
    go_terms = Array.new
    terms.each do |go_term, freq|
        go_terms.append(Annotation.new(go_term))
    end
    if go_terms.length == 0
        go_terms = "Not found"
    end

    annotated_network_array.append(AnnotatedNetwork.new({:int_array => inter_network.get_interactors_array, :GO => go_terms, :KEGG =>max_path}))
end

puts
i = 0
File.open("output.txt", "w") do |f| 
    if annotated_network_array.length == 0
        f.write("EMPTY FILE. No interactions found for the genes in file #{file_path} with intact-miscore > #{miscore}.\n")
        puts "EMPTY FILE. Please check log.txt file"
    else
        f.write("-----------------------------------------------------\n")
        annotated_network_array.each do |network|
            i+=1
            f.write("Network #{i}\n")
            f.write("Gene list: #{network.get_interactors_array.join(", ")}\n")
            f.write("KEGG pathway: ")
            if network.get_kegg == "Not found"
                f.write("Not found\n")
            else
                f.write(network.get_kegg.get_annotation+"\n") 
            end 
            f.write("GO terms: ")
            if network.get_go == "Not found"
                f.write("Not found")
            else
                terms = Array.new
                network.get_go.each do |go|
                    terms.append(go.get_annotation) unless network.get_go.nil?
                end
                f.write(terms.join(", "))
            end
            f.write("\n-----------------------------------------------------\n")
        end
        puts "THE END. Please check #{out_path} for results."
    end
end


