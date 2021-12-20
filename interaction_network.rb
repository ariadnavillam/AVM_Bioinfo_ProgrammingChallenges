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
    end
    
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

