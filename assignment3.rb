require 'net/http'
require 'bio'

def fetch(uri_str)  # this "fetch" routine does some basic error-handling.  
  address = URI(uri_str)  
  response = Net::HTTP.get_response(address)
  case response   # the "case" block allows you to test various conditions... it is like an "if", but cleaner!
    when Net::HTTPSuccess then  # when response is of type Net::HTTPSuccess
      return response  # return that response object
    else
      raise Exception, "Something went wrong... the call to #{uri_str} failed; type #{response.class}"
      response = false
      return response  # now we are returning False
    end
end
  
genes = File.open('./short_gene_list.txt', 'r')
genearray = genes.read.split() # this will read each line into an array
genes.close
  
fastaoutput = File.open('./genes.fa', 'w')
gene_with_exon = Array.new

genearray = ["AT1G22690"]
genearray.each do |geneid|
  
  url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{geneid}"
  res = fetch(url)  # we really should check that the return value is valid, but... 
  emblfile = Bio::FlatFile.new(Bio::EMBL, StringIO.new(res.body))
  emblfile.each_entry do |entry|
    seq_gen = entry.to_biosequence
    
    entry.features.each do |feature|
      if feature.feature == "exon"
        if feature.position.include? ":" #location in a remote entry
          next
        elsif feature.position.include? "complement"
          strand = "-"
          exon_seq = seq_gen.splice(feature.position)
          match = feature.position.scan(/complement\((\d+..\d+)\)/)
          ex_ini, ex_fin = match[0].split("..")
        else
          strand = "+"
          exon_seq = seq_gen.splice(feature.position)
          ex_ini, ex_fin = feature.position.split("..")
        end

        gene_with_exon.append(geneid)
        positions = exon_seq.enum_for(:scan, /(?=(cttctt))/).map { Regexp.last_match.begin(0)} 
        positions.each do |index|
          next if index.nil?
          loc = "#{ex_ini.to_i+index}..#{ex_ini.to_i+index+5}"
          if strand == "-"
            loc = "complement(#{loc})"
          end
          print loc
        end
        positions_comp = exon_seq.enum_for(:scan, /(?=(gaagaa))/).map { Regexp.last_match.begin(0) }
        positions_comp.each do |index|
          next if index.nil?
          loc = "#{ex_ini.to_i+index}..#{ex_ini.to_i+index+5}"
          if strand == "+"
            loc = "complement(#{loc})"
          end
          print loc
          puts exon_seq.splice(loc)
        end
      end
    
    end
  end
end
genes_wo_exon = genearray - gene_with_exon.uniq() 
print genes_wo_exon
puts "DONE"