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
#simple function to return the information from an accession string
def get_chr_info (entry_accession)
  acc = entry_accession.split(":") 
  return acc[2..4]
end

#this function search for a motif in a sequence (exon).
#the strand_change parameter is useful to look in both strands of the gene
def motif_search(motif, exon, strand_change=false)
  ex_ini, ex_fin = exon[:loc].span #the span of a position in bio::embl is the beginning and the end of the position
  motif_loc = Array.new #array created to save all the motifs of one gene
  positions = exon[:seq].enum_for(:scan, /(?=(#{motif}))/).map { Regexp.last_match.begin(0)} #we use the scan funtion to look for the motif
  positions.each do |index| #for each match we analyse the strand and location
    next if index.nil?
    if exon[:strand] == "+" && strand_change == false
      loc = "#{ex_ini.to_i+index}..#{ex_ini.to_i+index+5}" #the end of the motif is 5 positions from the beginning
      n_strand = "+"
    elsif exon[:strand] == "+" && strand_change == true #in this case we are looking for aagaag motif so we have to change the strand
      loc = "complement(#{ex_ini.to_i+index-1}..#{ex_ini.to_i+index+5-1})"
      n_strand = "-"
    elsif exon[:strand] == "-" && strand_change == false
      loc = "complement(#{ex_fin.to_i-index-5}..#{ex_fin.to_i-index})"
      n_strand = "-"
    else
      loc = "#{ex_fin.to_i-index-5}..#{ex_fin.to_i-index}"
      n_strand ="+"
    end
    motif_loc.append([loc,n_strand]) #save every position and strand found
  end
  return motif_loc #return the array
end

def print_gff_line(feature, seq_id, geneid, chr_ini = 0, source ="." ) 
  #this function prints the line ina gff format when a feature is given, with chromosome coordinate or gene coordinates
  ini,fin = feature.position.span
  id = "ID=#{feature.assoc["id"]}"
  notes = "Note=#{feature.assoc["notes"]}"
  parent = "Parent=#{geneid}"
  att = [id] #change to create the file to upload to ensembl
  #att = [id,parent,notes]
  if chr_ini.to_i != 0
    chr_ini = chr_ini.to_i-1 #substract 1 to the 
  end
  output_array = [seq_id, source, feature.feature, chr_ini+ini, chr_ini+fin,".", feature.assoc["strand"],".",att.join(";")]
  return output_array.join("\t")
end

if ARGV.length == 1 #command line arguments handling
  unless File.exist?(ARGV[0]) 
    puts "Wrong gene file. Please enter a valid file containing a list of genes."
    puts "Input: $ ruby main.rb  genes_file.txt"
    exit(1)
  else
    gene_file = ARGV[0]
  end
else
  puts "Error. Wrong number of arguments. Please enter a file containing a list of genes."
  exit(1)
end

genes = File.open(gene_file, 'r')
genearray = genes.read.split() # this will read each line into an array
genes.close
#open output files
genesgff_output = File.open('./genes.gff3', 'w')
chrgff_output = File.open('./chromosome.gff3', 'w')
gene_with_motif = Array.new
#print first line with gff version
genesgff_output.puts "##gff-version 3"
chrgff_output.puts "##gff-version 3"
#count of the genes to print out
count = 0
genearray.each do |geneid|
  count +=1
  puts "Searching CTTCTT motif in gene #{geneid}(#{count}/#{genearray.length})..."
  url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{geneid}"
  res = fetch(url) 
  emblfile = Bio::FlatFile.new(Bio::EMBL, StringIO.new(res.body)) 
  emblfile.each_entry do |entry|
    chr_number, chr_ini, chr_fin = get_chr_info(entry.accession) unless entry.accession.nil? #get chrmosome information
    motifs = Hash.new() #hash to save the motifs and their exons
    seq_gen = entry.to_biosequence
    
    entry.features.each do |feature| #for each entry look for the exon feature and obtain the information
      if feature.feature == "exon"
        exon = Hash.new
        if feature.position.include? ":" #location in a remote entry
          next
        elsif feature.position.include? "complement"
          exon[:strand] = "-"     
        else
          exon[:strand] = "+"
        end
        exon.merge!({:exon_id => feature.assoc['note'][8..], :seq => seq_gen.splice(feature.position), :loc => Bio::Locations.new(feature.position)})
        motif_loc_array = Array.new()
        motif_loc_array.concat(motif_search("cttctt", exon)) #look for cttctt motif
        motif_loc_array.concat(motif_search("aagaag", exon, strand_change=true)) #look for aagaag motif (cttctt in the complementary strand)
        motif_loc_array.each do |d_key|
          motifs[d_key.clone] = Array.new unless motifs.keys.include?(d_key) 
          motifs[d_key.clone].append(exon[:exon_id]) #append all exons that have that motif
        end
      end
    end
    next if motifs.empty? #if not motifs found go to next entry
    chrgff_output.puts "#{chr_number}\t.\tgene\t#{chr_ini}\t#{chr_fin}\t.\t+\t.\tID=#{geneid}" #print gene feature in the file
    gene_with_motif.append(geneid) #saves genes with motif
    id = 0
    motifs.keys.each do |loc,strand| #for every motif generate a new bio embl feature
      id +=1
      feature = Bio::Feature.new('nucleotide_motif',Bio::Locations.new(loc))
      feature.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
      feature.append(Bio::Feature::Qualifier.new('strand', strand))
      feature.append(Bio::Feature::Qualifier.new('notes', motifs[[loc,strand]].join(","))) #notes with all the exons
      feature.append(Bio::Feature::Qualifier.new('id', motifs[[loc,strand]][0])) #use first exon as id
      entry.features << feature
    end
    
    entry.features.each do |feature| 
      if feature.feature == "nucleotide_motif" #look for the features created
        genesgff_output.puts print_gff_line(feature, geneid, geneid) #print line in gene gff file
        chrgff_output.puts print_gff_line(feature, chr_number, geneid, chr_ini=chr_ini) #print line in chromosme gff file
      end
    end
  end
end
genesgff_output.close
chrgff_output.close

genes_wo_motif = genearray - gene_with_motif.uniq #get genes without cttctt motif and write into a file
genes_wo_output = File.open("genes_wo_motif.txt", "w") 
genes_wo_output.puts genes_wo_motif.join("\n")
genes_wo_output.close
puts
puts "DONE! \nPlease check the gff files created for results."
puts
puts "#{genes_wo_motif.length} genes without CTTCTT motifs. Check genes_wo_motif.txt file."
puts
