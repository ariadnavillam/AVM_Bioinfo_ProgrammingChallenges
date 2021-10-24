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

def get_embl_record(geneid)
    $stderr.puts "calling http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{geneid}"
    if res = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{geneid}")
      body = res.body
      return body
    else
      abort "COULDN'T RETRIEVE EMBL RECORD"
    end
  end

def get_uniprot_id(body)
# /db_xref="Uniprot/SWISSPROT:P35631"
    match = body.match(/\/db_xref="Uniprot\/SWISSPROT:([^"]+)"/)
    if match.nil?
        uniprotid = NilClass
    else 
        uniprotid = match[1]
    end
    return uniprotid  
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
      abort "COULDN'T RETRIEVE EMBL RECORD"
    end
  end

def get_proteins(body)
    match = body.match(/$uniprotkb:\t/)
    if match.nil?
        uniprotid = NilClass
    else 
        puts match
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
    attr_accessor :GO_terms
    attr_accessor :KEGG_path

    def initialize
    interactors = Hash.new()
    end

    def get_interactors(uniprot_id)
        if interactors.key(uniprot_id)
            puts interactors
        end
    end
end

class KEGG_pathway
    attr_accessor :KEGG_ID
    attr_accessor :KEGG_name

    def initialize (params = {})
        
        @KEGG_ID = params.fetch(:KEGG_ID, "X000")
        @KEGG_name = params.fetch(:KEGG_name, "nameX")     
        
    end
end

class GO_term
    attr_accessor :GO_ID
    attr_accessor :GO_name
    def initialize (params = {})    
        @GO_ID = params.fetch(:GO_ID, "X000")
        @GO_name = params.fetch(:GO_name, "nameX")     
        
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


genes = Hash.new
File.open("genes.txt", "r").each do |f|
    row = f.strip.split("\t")
    h = {:Gene_ID => row[0], :Gene_name => row[1], :Uniprot_ID => row[2]}
    genes[row[0]] = Gene.new(h)
end

genes.each_key do |key|
    intact = get_int_record(genes[key].get_uniprot_id)
    fields = intact.split("\t")
    puts fields[0], fields[1]

end




# puts response.body



