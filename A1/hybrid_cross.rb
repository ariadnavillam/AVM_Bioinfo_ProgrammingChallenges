class HybridCross
    #initialize properties for hybridcross object based on the fields of the tsv file
    attr_accessor :Parent1
    attr_accessor :Parent2
    attr_accessor :F2_Wild
    attr_accessor :F2_P1
    attr_accessor :F2_P1P2
    attr_accessor :F2_P2

    def initialize (params = {})
        @Parent1 = params.fetch(:Parent1, "X000")
        @Parent2 = params.fetch(:Parent2, "X000")
        @F2_Wild = params.fetch(:F2_Wild, "X000").to_i
        @F2_P1 = params.fetch(:F2_P1, "X000").to_i
        @F2_P2 = params.fetch(:F2_P2, "X000").to_i
        @F2_P1P2 = params.fetch(:F2_P1P2, "X000").to_i
        
    end

    def get_parents
        return [@Parent1, @Parent2]
    end

    def test_link
        #get the genes related to each of the parents

        # performs the chi square test to see it two genes are linked
        observed_F2 = [@F2_Wild, @F2_P1, @F2_P2, @F2_P1P2]
        total_F2 = observed_F2.sum
        
        #the fractions expected for F2 are the following
        expected = [9/16.to_f, 3/16.to_f, 3/16.to_f, 1/16.to_f]
        #multiply that value for the total and save 
        i=0
        expected.each do |value|
            expected[i] = value * total_F2
            i+=1
        end
        #apply the chi-square formula with the observed values and the calculated expected values
        chi_formula = Array.new(4)
        j=0
        expected.each do |exp_value|
            chi_formula[j] = ((observed_F2[j] - exp_value)**2)/exp_value
            j+=1
        end
        #sum the results of the formula
        chi_square = chi_formula.sum
        #for a degree of freedom of 3 and a p value < 0.05
        #the value of chi square must be greater than 7.817 to be considered statiscally significant
        return chi_square
    end

    
end
