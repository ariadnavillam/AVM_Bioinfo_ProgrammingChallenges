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

def get_uniprot_record(geneid)
  $stderr.puts "calling https://www.uniprot.org/uniprot/?query=#{geneid}&columns=id,genes&format=tab"
  if res = fetch("https://www.uniprot.org/uniprot/?query=#{geneid}&columns=id,genes&format=tab")
    body = res.body
    return body
  else
    puts "COULDN'T RETRIEVE UNIPROT RECORD"
    return nil
  end
end

def get_uniprot_id(body)
  lines = body.split("\n")
  lines.each do |line|
    fields = line.split("\t")
    if fields[0].match(/\A[A-Z1-9]{6}\z/) 
      puts fields[0]
      return fields[0]  
    else
      next  
    end
  end
end


def get_gene_name(body)
  lines = body.split("\n")
  fields = lines[1].split("\t")
  alt_names = fields[1].split(" ")
  if alt_names[0].nil?
    return nil
  else 
    return alt_names[0]
  end
end

def get_int_record(protid)
    $stderr.puts "calling http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{protid}"
    if res = fetch("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{protid}")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE INTACT RECORD"
      return nil
    end
end

def get_kegg_record(geneid)
    $stderr.puts "calling http://rest.kegg.jp/get/ath:#{geneid}"
    if res = fetch("http://rest.kegg.jp/get/ath:#{geneid}")
      body = res.body
      return body
    else
      puts "COULDN'T RETRIEVE KEGG PATHWAY"
      return nil
    end
end

def get_kegg_path(body)
    match = body.scan(/(ath[0-9]{5})\s+([A-Z].+$)/)
    if match.nil?
        return nil
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
      return nil
    end
end

def get_go_terms(body)
    match = body.scan(/"goId":"(GO:\d+)","goName":"([a-z ]+)","goEvidence"/)
    if match.nil?
        return nil
    else 
        go_terms = Array.new
        match.each do |go|
            go_terms.append(Annotation.new({:ID => go[0], :name => go[1]}))
        end
        return go_terms
    end 
end

