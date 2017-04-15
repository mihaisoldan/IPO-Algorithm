#the class 'Parameter' models a Factor/Parameter 
class IPOAlgorithm::Parameter
	attr_reader :name, :no_levels, :values

	def initialize(name, levels)
		@values = Array.new
		@name = name
		@no_levels = levels
		#each value is represented using the lowercase version of the factor's name and an index subscript starting from 1 up to the number of levels of the factor 
		1.upto(levels) {|i| values << name.downcase + i.to_s}
	end 
end
