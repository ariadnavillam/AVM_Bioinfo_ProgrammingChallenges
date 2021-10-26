require 'rest-client'  
require 'csv'
require 'json'  # to handle JSON format

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

def get_uniprot_id(geneid)
    $stderr.puts "calling http://togows.org/entry/ebi-uniprot/#{geneid}/accessions"
    if res = fetch("http://togows.org/entry/ebi-uniprot/#{geneid}/accessions")
      body = res.body
      accession = body.split("\t")
      return accession[0]
    else
      puts "COULDN'T RETRIEVE UNIPROT RECORD"
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

def get_int_record(protid)
    $stderr.puts "calling http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{protid}"
    if res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{protid}")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE INTACT RECORD"
      return NIL
    end
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
        return kegg_paths
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
    match = body.scan(/"goId":"(GO:\d+)","goName":"([a-z ]+)","goEvidence"/)
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

    def get_interactor_array
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


# File.open("genes.txt", "w") do |f|
#     genes_file = CSV.read("head_genes.txt")
#     genes = Hash.new()
#     genes_file.each do |gene_id|
#         gene_id = gene_id[0]
#         gene_properties = {:Gene_ID => gene_id}
#         embl = get_embl_record(gene_id)
#         gene_properties[:Uniprot_ID] = get_uniprot_id(embl)
#         gene_properties[:Gene_name] = get_gene_name(embl)
#         genes[gene_id] = Gene.new(gene_properties)
#         f.write(genes[gene_id].get_all)
#         f.write("\n")
#     end
# end


def get_interaction_genes(uniprot_id,new_genes_hash,n)
    if n == 0
        return
    end
    intact = get_int_record(uniprot_id)
    unless intact == NIL
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

genes = Hash.new
File.open("genes.txt", "r").each do |f|
    row = f.strip.split("\t")
    h = {:Gene_ID => row[0], :Gene_name => row[1], :Uniprot_ID => row[2]}
    genes[row[0]] = Gene.new(h)
end

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
end
