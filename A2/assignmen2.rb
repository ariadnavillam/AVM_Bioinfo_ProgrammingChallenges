require 'rest-client'  
require 'csv'
require 'json'  # to handle JSON format
<<<<<<< HEAD:assignmen2.rb
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
=======

# Create a function called "fetch" that we can re-use everywhere in our code

def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end

# def get_uniprot_id(geneid)
#     $stderr.puts "calling http://togows.org/entry/ebi-uniprot/#{geneid}/accessions"
#     if res = fetch("http://togows.org/entry/ebi-uniprot/#{geneid}/accessions")
#       body = res.body
#       accession = body.split("\t")
#       return accession[0]
#     else
#       puts "COULDN'T RETRIEVE UNIPROT RECORD"
#       return NIL
#     end
# end

def get_int_record(geneid)
    $stderr.puts "calling http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{geneid}"
    if res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{geneid}")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE INTACT RECORD"
      return NIL
    end
end

def get_gene_name(body)
    # /locus_tag="AP1"
    match = body.match(/\/locus_tag="([^"]+)"/)
    if match.nil?
      genename = NilClass
    else 
        genename = match[1]
    end  
    return genename
end

def get_kegg_record(geneid)
    $stderr.puts "calling http://rest.kegg.jp/get/ath:#{geneid}"
    if res = fetch("http://rest.kegg.jp/get/ath:#{geneid}")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE KEGG PATHWAY"
      return NIL
    end
end

def get_kegg_path(body)
    match = body.scan(/(ath[0-9]{5})\s+([A-Z].+$)/)
    if match.nil?
        return NIL
    else
        kegg_path = Array.new
        print match
        match.each do |kegg|
            kegg_path.append(Annotation.new({:ID => kegg[0], :name => kegg[1]}))
        end
        return kegg_path
    end
end

def get_go_record(protid)
    $stderr.puts "calling https://www.ebi.ac.uk/QuickGO/services/annotation/search?includeFields=goName&geneProductId=#{protid}&aspect=biological_process&qualifier=involved_in"
    if res = fetch("https://www.ebi.ac.uk/QuickGO/services/annotation/search?includeFields=goName&geneProductId=#{protid}&aspect=biological_process&qualifier=involved_in")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE GO RECORD"
      return NIL
    end
end

def get_go_terms(body)
    match = NIL
    match = body.scan(/"goId":"(GO:\d+)","goName":"([a-z ]+)","goEvidence"/) unless body.nil?
    if match.nil?
        return NIL
    else 
        go_terms = Array.new
        match.each do |go|
            go_terms.append(Annotation.new({:ID => go[0], :name => go[1]}))
        end
        return go_terms
    end 
end


class InteractionNetwork
    attr_accessor :Interactors

    def initialize(params)
        @Interactors = params.fetch(:int_array)
    end

    def add_interactors(array)
        @Interactors.concat(array)
    end

    def add_interactor(interactor)
        @Interactors.append(interactor)
    end

    def get_interactors_array
        return @Interactors
    end
end

class AnnotatedNetwork < InteractionNetwork
    attr_accessor :KEGG
    attr_accessor :GO

    def initialize (params = {})
        super(params)
        @KEGG = params.fetch(:KEGG, "X000")
        @GO = params.fetch(:GO, "X000")     
        
    end  

end


class Annotation 
    attr_accessor :ID
    attr_accessor :name

    def initialize (params = {})
        
        @ID = params.fetch(:ID, "X000")
        @name = params.fetch(:name, "nameX")     
        
    end

end 

def get_interaction_genes(gene_id, origin_genes, new_genes_array, ini_gene, n)
    if n == 0
        return
    end
    intact = get_int_record(gene_id)
    unless intact == NIL
>>>>>>> b8a72268c0c4fde0b32c83525d900557c2d12ee2:A2/assignmen2.rb
        rows = intact.split("\n")
        rows.each do |row|
            #prots = row.scan(/^uniprotkb:(\w+)\tuniprotkb:(\w+)/).flatten
            locus = row.scan(/uniprotkb:(A\w+)\(locus name\)/).flatten
            #name = row.scan(/uniprotkb:(\w+)\(gene name\)/).flatten
            score = row.scan(/intact-miscore:([0-9\.]+)/).flatten
            locus.each do |i_locus|
                if origin_genes.key?(i_locus) && i_locus != gene_id
                    new_genes_array.append(i_locus)
                else
                    get_interaction_genes(i_locus, origin_genes, new_genes_array, ini_gene, n-1)
                end
            end
        end
    end
end

<<<<<<< HEAD:assignmen2.rb
# genes = Hash.new
# File.open("genes.txt", "r").each do |f|
#     row = f.strip.split("\t")
#     h = {:Gene_ID => row[0], :Gene_name => row[1], :Uniprot_ID => row[2]}
#     genes[row[0]] = Gene.new(h)
# end
=======
origin_genes = Hash.new
File.foreach("ArabidopsisSubNetwork_GeneList.txt") do |line|
#File.foreach("head_genes.txt") do |line|
    gene = line.strip
    gene = gene.sub("T","t")
    origin_genes[gene] = Array.new
end
>>>>>>> b8a72268c0c4fde0b32c83525d900557c2d12ee2:A2/assignmen2.rb

origin_genes.each_key do |gene_key|
    new_genes = Array.new
    get_interaction_genes(gene_key, origin_genes, new_genes, gene_key, 1)
    origin_genes[gene_key] = new_genes
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
    int_array.each do |prot|
        record = get_kegg_record(prot)
        paths.concat(get_kegg_path(record))
    end

    freq = paths.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
    max_path = paths.max_by { |v| freq[v] }

    terms = Array.new
    int_array.each do |prot|
        go_rec = get_go_record(prot)
        terms.concat(get_go_terms(go_rec)) unless go_rec.nil?
    end

<<<<<<< HEAD:assignmen2.rb
an_inter_network = Hash.new
an_inter_network[gene] = AnnotatedNetwork.new({:int_array => inter_network[gene].get_interactor_array, :GO => go_terms, :KEGG =>max_path})
=======
    go_terms = terms.uniq

    annotated_network_array.append(AnnotatedNetwork.new({:int_array => inter_network.get_interactors_array, :GO => go_terms, :KEGG =>max_path}))
end

print annotated_network_array
>>>>>>> b8a72268c0c4fde0b32c83525d900557c2d12ee2:A2/assignmen2.rb
