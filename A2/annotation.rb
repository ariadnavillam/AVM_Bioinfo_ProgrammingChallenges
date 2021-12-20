class Annotation 
    attr_accessor :ID
    attr_accessor :name

    def initialize (params = {})
        
        @ID = params.fetch(:ID, "X000")
        @name = params.fetch(:name, "nameX")     
        
    end

    def get_annotation
        return "#{@ID} (#{@name})"
    end

end 