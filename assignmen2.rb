require 'rest-client'  
require 'csv'
require 'json'  # to handle JSON format
require './gene.rb'
require './general_annotation.rb'
require './interaction_network.rb'
require './web_function.rb'

File.open("genes.txt", "w") do |f|
    genes_file = CSV.read("head_genes.txt")
    genes = Hash.new()
    genes_file.each do |gene_id|
        gene_id = gene_id[0]
        gene_properties = {:Gene_ID => gene_id}
        uniprot = get_uniprot_record(gene_id)
        gene_properties[:Uniprot_ID] = get_uniprot_id(uniprot)
        gene_properties[:Gene_name] = get_gene_name(uniprot)
        genes[gene_id] = Gene.new(gene_properties)
        f.write(genes[gene_id].get_all)
        f.write("\n")
    end
end

def get_interaction_genes(uniprot_id,new_genes_hash,n)
    if n == 0
        return
    end
    intact = get_int_record(uniprot_id)
    unless intact == nil
        rows = intact.split("\n")
        rows.each do |row|
            prots = row.scan(/^uniprotkb:(\w+)\tuniprotkb:(\w+)/).flatten
            locus = row.scan(/uniprotkb:(A\w+)\(locus name\)/).flatten
            name = row.scan(/uniprotkb:(\w+)\(gene name\)/).flatten
            [0,1].each do |i|
                unless prots[i] == uniprot_id
                    new_genes_hash[prots[i]] = {:Uniprot_ID => prots[i], :Gene_ID => locus[i], :Gene_name => name[i]}
                    get_interaction_genes(prots[i], new_genes_hash, n-1)
                end
            end
        end
    end
end

# genes = Hash.new
# File.open("genes.txt", "r").each do |f|
#     row = f.strip.split("\t")
#     h = {:Gene_ID => row[0], :Gene_name => row[1], :Uniprot_ID => row[2]}
#     genes[row[0]] = Gene.new(h)
# end

new_genes = Hash.new
gene = "AT4g37610"
prot = "Q6EJ98"

get_interaction_genes("Q6EJ98", new_genes, 1)
array = Array.new
new_genes.each_value do |value|
    array.append(value[:Uniprot_ID])
end

inter_network = Hash.new
inter_network[gene]= InteractionNetwork.new({:int_array => array.uniq})


int_array = inter_network[gene].get_interactor_array
paths = Array.new
int_array.each do |prot|
    record = get_kegg_record(prot)
    paths.concat(get_go_terms(record))
end

freq = paths.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
max_path = paths.max_by { |v| freq[v] }

terms = Array.new
int_array.each do |prot|
    go_rec = get_go_record(prot)
    terms.concat(get_go_terms(go_rec))
end

go_terms = terms.uniq

an_inter_network = Hash.new
an_inter_network[gene] = AnnotatedNetwork.new({:int_array => inter_network[gene].get_interactor_array, :GO => go_terms, :KEGG =>max_path})
