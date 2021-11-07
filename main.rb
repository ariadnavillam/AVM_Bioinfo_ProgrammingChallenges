require 'rest-client'  
require 'csv'
require 'json'  
require './web_functions.rb'
require './interaction_network.rb'
require './annotation.rb'
require './gene.rb'


origin_genes = Hash.new
File.foreach("ArabidopsisSubNetwork_GeneList.txt") do |line|
#File.foreach("head_genes.txt") do |line|
    gene = line.strip
    gene = gene.sub("T","t")
    origin_genes[gene] = Array.new
end

gene_information = Hash.new
origin_genes.each_key do |gene_key|
    new_genes = Array.new
    get_interaction_genes(gene_key, origin_genes, new_genes, gene_key, 3)
    int_genes = Array.new
    new_genes.each do |new_gene|
        int_genes.append(new_gene[0]) unless new_gene[0] == gene_key
        gene_information[new_gene[0]] = Gene.new({:Gene_ID => new_gene[0], :Uniprot_ID => new_gene[1], :Gene_name => new_gene[2]}) unless gene_information.key?(new_gene)
    end
    origin_genes[gene_key] = int_genes
end


origin_genes.each_pair do |key, value|
    value.each do |int_gene|
        origin_genes[int_gene].delete(key)
    end
end

inter_network_array = Array.new
origin_genes.each_pair do |key, value|
    if value.length > 0
        array = value
        array.append(key)
        inter_network_array.append(InteractionNetwork.new({:int_array => array.uniq}))
    end
end

annotated_network_array = Array.new
inter_network_array.each do |inter_network|
    int_array = inter_network.get_interactors_array
    paths = Array.new
    int_array.each do |geneid|
        record = get_kegg_record(geneid)
        paths.concat(get_kegg_path(record))
    end

    freq = paths.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
    max_path = paths.max_by { |v| freq[v] }

    terms = Array.new
    int_array.each do |geneid|
        go_rec = get_go_record(gene_information[geneid].get_uniprot_id) unless gene_information[geneid].nil?
        terms.concat(get_go_terms(go_rec)) unless go_rec.nil?
    end

    terms = terms.uniq
    go_terms = Array.new()
    terms.each do |go_term|
        go_terms.append(Annotation.new(go_term))
    end
    annotated_network_array.append(AnnotatedNetwork.new({:int_array => inter_network.get_interactors_array, :GO => go_terms, :KEGG =>max_path}))
end
i = 0
File.open("output.txt", "w") do |f| 
    f.write("-----------------------------------------------------\n")
    annotated_network_array.each do |network|
        i+=1
        f.write("Network #{i}\n")
        f.write("Gene list: #{network.get_interactors_array.join(", ")}\n")
        f.write("KEGG pathway: #{network.get_kegg.get_annotation}\n")
        f.write("GO terms:\n")
        network.get_go.each do |go|
            f.write("#{go.get_annotation}\n")
        end
        f.write("\n-----------------------------------------------------\n")
        
    end
end

