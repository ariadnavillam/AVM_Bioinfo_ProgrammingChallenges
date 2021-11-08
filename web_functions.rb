require 'rest-client'  

require 'json'

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

def get_kegg_path(body)
    match = NIL
    match = body.scan(/(ath[0-9]{5})\s+([A-Z].+$)/)
    if match.nil?
        return NIL
    else
        kegg_path = Array.new
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
      match.each do |go|
        go_terms.append({:ID => go[0], :name => go[1]})
      end
      return go_terms
    end 
end

def get_interaction_genes(gene_id, origin_genes, new_genes_array, ini_gene, n, score_limit)
    if n == 0
        return
    end
    intact = get_int_record(gene_id)
    unless intact == NIL
        rows = intact.split("\n")
        rows.each do |row|
            prots = row.scan(/^uniprotkb:(\w+)\tuniprotkb:(\w+)/).flatten
            locus = row.scan(/uniprotkb:(A\w+)\(locus name\)/).flatten
            name = row.scan(/uniprotkb:(\w+)\(gene name\)/).flatten
            score = row.scan(/intact-miscore:([0-9\.]+)/)
            if score[0][0].to_f > score_limit
              [0,1].each do |i|
                  if origin_genes.key?(locus[i]) && locus[i] != gene_id
                    new_genes_array.append([locus[i], prots[i], name[i]])
                  else
                    get_interaction_genes(locus[i], origin_genes, new_genes_array, ini_gene, n-1, score_limit)
                  end
              end
            end
        end
    end
end