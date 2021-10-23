class SeedStock
    #initialize properties for seedstock object based on the fields of the tsv file
    attr_accessor :Seed_Stock
    attr_accessor :Mutant_Gene_ID
    attr_accessor :Last_Planted
    attr_accessor :Storage
    attr_accessor :Grams_Remaining


    def initialize (params = {})
        @Mutant_Gene_ID = params.fetch(:Mutant_Gene_ID, "X000")
        @Seed_Stock = params.fetch(:Seed_Stock, "X000") 
        @Last_Planted = params.fetch(:Last_Planted, "X000")
        @Storage = params.fetch(:Storage, "X000")
        @Grams_Remaining = params.fetch(:Grams_Remaining, "X000").to_i
    end

    def plant(grams=7)
        #function to plant 7 grams of each seed 
        new_grams = @Grams_Remaining - grams
        if new_grams > 0
            @Grams_Remaining = new_grams
        
        else
            @Grams_Remaining = 0
            puts "WARNING! We have run out of Seed Stock #{@Seed_Stock}."
         end
    end

    def get_gene
        return @Mutant_Gene_ID 
    end
    
    def get_seed
        return @Seed_Stock
    end

    def get_properties #this methos puts each of the properties of each object to print to a new file
        return "#{@Seed_Stock}\t#{@Mutant_Gene_ID}\t#{@Last_Planted}\t#{@Storage}\t#{@Grams_Remaining}\n"
    end

        

end
