require 'rest-client'  

#same function we used in class
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

#function to retrieve each intact page
def get_int_record(geneid)
    $stderr.puts "calling http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{geneid}"
    if res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{geneid}")
      body = res.body
      return body
    else
      $stderr.puts "COULDN'T RETRIEVE INTACT RECORD"
      return NIL
    end
end

#retrieve the kegg page for a gene
def get_kegg_record(geneid)
    $stderr.puts "calling http://rest.kegg.jp/get/ath:#{geneid}"
    if res = fetch("http://rest.kegg.jp/get/ath:#{geneid}")
      body = res.body
      return body
    else
      $stderr.puts "COULDN'T RETRIEVE KEGG PATHWAY"
      return NIL
    end
end

#search for the paths in the kegg page
def get_kegg_path(body)
    match = NIL
    match = body.scan(/(ath[0-9]{5})\s+([A-Z].+$)/)
    if match.nil?
        return NIL
    else
        kegg_path = Array.new
        match.each do |kegg| #save each path as an annotation
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
      $stderr.puts "COULDN'T RETRIEVE GO RECORD"
      return NIL
    end
end

def get_go_terms(body)
    match = NIL
    match = body.scan(/"goId":"(GO:\d+)","goName":"([a-zA-Z ]+)","goEvidence"/) unless body.nil?
    if match.nil?
      return NIL
    else 
      go_terms = Array.new
      match.each do |go| #save it as a dictionary so in main can be saved as annotation object
        go_terms.append({:ID => go[0], :name => go[1]})
      end
      return go_terms
    end 
end

#recursive function to obtain the interation genes
def get_interaction_genes(gene_id, origin_genes, new_genes_array, ini_gene, n, score_limit)
    if n == 0 #frist condition if the search depth is bigger than n return the function. this is neccesary so that the function is finite
        return
    end
    intact = get_int_record(gene_id)
    unless intact.nil? #if the gene id is not found the function stops
        rows = intact.split("\n") #divide by row
        rows.each do |row|
            prots = row.scan(/^uniprotkb:(\w+)\tuniprotkb:(\w+)/).flatten #get the proteins id
            locus = row.scan(/uniprotkb:(A\w+)\(locus name\)/).flatten #get the locus id
            name_fields = row.split("\t") #divide by fields and get the gene name or synonims but only the first that appears
            name = [name_fields[4].scan(/uniprotkb:(\w+)\(gene name/).flatten[0], name_fields[5].scan(/uniprotkb:(\w+)\(gene name/).flatten[0]]
            score = row.scan(/intact-miscore:([0-9\.]+)/) 
            #if the score was not found the default value is 0
            begin
              score = score[0][0].to_f
            rescue
              score = 0.0
            end 
            if score > score_limit #if score is higher that the filter we asked in the command line the interaction is considered
              [0,1].each do |i|
                  if origin_genes.key?(locus[i]) && locus[i] != gene_id # the gene is saved only if it is in the gene list and if it is not the gene we are searching for
                    new_genes_array.append([locus[i], prots[i], name[i]])
                  elsif locus[i] != gene_id #repeat the function for the new genes
                    get_interaction_genes(locus[i], origin_genes, new_genes_array, ini_gene, n-1, score_limit)
                  end
              end
            end
        end
    end
end