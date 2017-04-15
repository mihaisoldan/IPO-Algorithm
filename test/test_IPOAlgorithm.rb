require 'test/unit'
require_relative '../lib/IPOAlgorithm.rb'

#tests the response of the algorithm with only the first 2 arguments provided
class TestIpoWithoutCSV < Test::Unit::TestCase

	#it specifies the maximum number of parameters to be tested
	def setup
		@no_tests = 2
	end

	#tests if the algorithm spots invalid inputs
	def test_invalid_number_of_parameters
		assert_raise(ArgumentError.new("The number of parameters passed as an argument must be an Integer.")) {IPOAlgorithm.new(3.5,[3,5,5])}
		assert_raise(ArgumentError.new("The IPOAlgorithm can process at most 26 parameters (at least 2 parameters must be provided)")) {IPOAlgorithm.new(27,[3,5,5])}
		assert_raise(ArgumentError.new("The IPOAlgorithm can process at most 26 parameters (at least 2 parameters must be provided)")) {IPOAlgorithm.new(1,[3,5,5])}
	end

	#tests if the algorithm recognizes when the specified number of parameters doesn't correspond to the size of the array representing the levels for each parameter
	def test_different_no_parameters
		assert_raise(ArgumentError.new("The number of parameters doesn't match the size of the array argument representing the number of levels for each parameter.")) {IPOAlgorithm.new(3,[3,5,5,4])}
	end

	#tests if the algorithm recognizes when the specified number of levels for a parameter isn't a valid value
	def test_invalid_levels
		assert_raise(ArgumentError.new("The number of levels for each argument must be an Integer.")) {IPOAlgorithm.new(3,[3,5,"a"])}
	end

	#test if all the pairs have been covered; to do so the Kernel#eval method is used to create objects of IPO class dynamically and to test the pairwise coverage
	def test_all_pairs_covered
		puts "\n"
		2.upto(@no_tests) do |no_factors|
			levels="["
			1.upto(no_factors) {|factor| levels += rand(2...10 ).to_s + ","}
			levels[levels.size-1] = "]"
			declaration = "@ipo_#{no_factors}_factors = IPOAlgorithm.new(#{no_factors}, #{levels})"
			puts declaration + " ----->I'm testing #{no_factors} factors"
			eval declaration
			eval "assert_not_nil @ipo_#{no_factors}_factors"
			eval "assert_equal @ipo_#{no_factors}_factors.class, IPOAlgorithm"
			eval "assert all_pairs_covered @ipo_#{no_factors}_factors"

		end
	end

	#method that given an IPO object outputs a boolean value indicating the pairwise coverage
	def all_pairs_covered(ipo)
		all_pairs = []
		0.upto(ipo.no_parameters-2) do |index1|
			(index1+1).upto(ipo.no_parameters-1) do |index2|
				all_pairs += ipo.instance_eval {pairs(index1,index2)}
			end
		end
		ipo.runs.each {|r| all_pairs -= ipo.instance_eval{pairs_for_run(r)}}
		(all_pairs-ipo.infeasible_pairs).empty?
	end
end

#tests the algorithm response with the first two mandatory arguments and the third optional one containing the path to the .csv file with the actual values of the parameters; the pairwise coverage isn't tested because it is the same as for the TestIpoWithoutCSV tests.
class TestIpoWithCSV < Test::Unit::TestCase

	#tests if the .csv file has been correctly read and the tabular representation created
	def test_table_created
		@ipo = IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/input_file.csv")
		assert_not_nil @ipo.actual_parameters
	end
	#tests if the algorithm spots invalid .csv files
	def test_invalid_file
		assert_raise(ArgumentError.new("It wasn't possible to read from invalid_file.csv file.")) {IPOAlgorithm.new(3,[3,5,5],"invalid_file.csv")}
	end

	#test if the algorithm recognizes a discrepancy between the values of the first two arguments and the values contained within the .csv file
	def test_incorrect_csv
		assert_raise(ArgumentError.new("The number of factors in the CSV file doesn't correspond to the specified value")) {IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/incorrect_file.csv")}
		assert_raise(ArgumentError.new("The number of levels doesn't correspond to the specified values")) {IPOAlgorithm.new(3,[3,4,5],File.dirname(__FILE__)+"/input_file.csv")}
	end
end

#tests the algorithm response when all four arguments are provided
class TestIpoWithCSVandInfeasiblePairs < Test::Unit::TestCase

	#tests if the algorithm recognizes invalid files for the infeasible pairs
	def test_invalid_file
		assert_raise(ArgumentError.new("It wasn't possible to read from #{File.dirname(__FILE__)}/invalid_infeasible_file.csv file.")) {IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/input_file.csv",File.dirname(__FILE__)+"/invalid_infeasible_file.csv")}
	end

	#tests if the algorithm spots rows of the .csv file containing infeasible pairs with less or more than 2 values
	def test_not_all_lines_are_pairs
		assert_raise(ArgumentError.new("Every line of the .csv file containing infeasible pairs must contain exactly 2 elements")) {IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/input_file.csv",File.dirname(__FILE__)+"/infeasible_pairs_not_all_pairs.csv")}
	end

	#tests if the algorithm recognizes values specified by the .csv file containing infeasible pairs that have not been declared by the .csv file containing the actual values of the paramenters
	def test_unspecified_level
		assert_raise(ArgumentError.new("Windows 10 Enterprise level specified in the #{File.dirname(__FILE__)}/infeasible_pairs_unspecified_level.csv file doesn't belong to any parameter in the #{File.dirname(__FILE__)}/input_file.csv file")) {IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/input_file.csv",File.dirname(__FILE__)+"/infeasible_pairs_unspecified_level.csv")}
	end

	#tests if the algorithm spots infeasible pairs for which it is impossible to obtain valid runs; more precisely this impossibility is spotted within the Vertical Growth step of the algorithm.
	def test_impossible_combination_VG
		assert_raise(ArgumentError.new("The input provided doesn't allow the creation of valid runs(raised in vertical_growth)")) {IPOAlgorithm.new(3,[2,2,2],File.dirname(__FILE__)+"/input_file_impossible_combination_VG.csv",File.dirname(__FILE__)+"/infeasible_pairs_impossible_combination_VG.csv")}
	end

	#tests if the algorithm spots infeasible pairs for which it is impossible to obtain valid runs; more precisely this impossibility is spotted within the Horizontal Growth step of the algorithm.
	def test_impossible_combination_HG
		assert_raise(ArgumentError.new("The input provided doesn't allow the creation of valid runs(raised in horizontal_growth)")) {IPOAlgorithm.new(3,[2,3,2],File.dirname(__FILE__)+"/input_file_impossible_combination_HG.csv",File.dirname(__FILE__)+"/infeasible_pairs_impossible_combination_HG.csv")}
	end

	#test if indeed no infeasible pair has been covered
	def test_no_infeasible_pair_covered
		assert TestIpoWithoutCSV.new(5).all_pairs_covered(IPOAlgorithm.new(3,[3,5,5],File.dirname(__FILE__)+"/input_file.csv",File.dirname(__FILE__)+"/infeasible_pairs.csv"))
	end
end
