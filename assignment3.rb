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

#genearray = ["AT1G22690"]
genearray.each do |geneid|
  
  url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{geneid}"
  res = fetch(url)  # we really should check that the return value is valid, but... 
  emblfile = Bio::FlatFile.new(Bio::EMBL, StringIO.new(res.body))
  emblfile.each_entry do |entry|
    motifs = Array.new()
    seq_gen = entry.to_biosequence
    
    entry.features.each do |feature|
      if feature.feature == "exon"
        if feature.position.include? ":" #location in a remote entry
          next
        elsif feature.position.include? "complement"
          strand = "-"     
        else
          strand = "+"
        end
        exon_seq = seq_gen.splice(feature.position)
        loc = Bio::Locations.new(feature.position)
        ex_ini, ex_fin = loc.span
        gene_with_exon.append(geneid)

        positions = exon_seq.enum_for(:scan, /(?=(cttctt))/).map { Regexp.last_match.begin(0)} 
        positions.each do |index|
          next if index.nil?
          if strand == "+"
            loc = "#{ex_ini.to_i+index}..#{ex_ini.to_i+index+5}"
          else
            loc = "complement(#{ex_fin.to_i-index-5}..#{ex_fin.to_i-index})"
          end
          motifs.append([loc,strand,"cttctt"])
        end

        positions_comp = exon_seq.enum_for(:scan, /(?=(gaagaa))/).map { Regexp.last_match.begin(0) }
        positions_comp.each do |index|
          next if index.nil?
          if strand == "+"
            loc = "#{ex_ini.to_i+index}..#{ex_ini.to_i+index+5}"
            strand = "-"
          else
            loc = "complement(#{ex_fin.to_i-index-5}..#{ex_fin.to_i-index})"
            strand = "+"
          end
          motifs.append([loc,strand, "gaagaa"])
        end
      end
    
    end
    motifs = motifs.uniq()
    motifs.each do |loc,strand,m|
      print [seq_gen.splice(loc),strand,m] if seq_gen.splice(loc) != m
      puts
      strand = "+"
      strand = "-" if loc.include? "complement"
      feature = Bio::Feature.new('repeat',Bio::Locations.new(loc))
      feature.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
      feature.append(Bio::Feature::Qualifier.new('strand', strand))
      entry.features << feature
    end
    
    entry.features.each do |feature|
      if feature.feature == "repeat"
        ini,fin = feature.position.span
        #puts "#{geneid}\t.\t#{feature.assoc["repeat_motif"]}\t#{ini}\t#{fin}\t.\t#{feature.assoc["strand"]}\t.\t"
      end
    end
    
  end
end
genes_wo_exon = genearray - gene_with_exon.uniq() 
print genes_wo_exon
puts "DONE"