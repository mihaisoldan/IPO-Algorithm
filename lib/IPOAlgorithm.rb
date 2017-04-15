
require 'terminal-table'
require 'csv'

class IPOAlgorithm

	attr_reader :no_parameters
	attr_reader :levels
	attr_reader :parameters
	attr_reader :runs
	attr_reader :actual_parameters
	attr_reader :infeasible_pairs
	attr_reader :output_table
	def initialize(no_parameters,levels,csv=nil,infeasible_csv=nil)
		#
		#preliminary checks of the arguments passed to the algorithm and initialization of the '@no_parameters' instance_variable
		#
		raise ArgumentError, "The number of parameters passed as an argument must be an Integer." unless no_parameters.is_a? Integer
		@no_parameters = no_parameters
		raise ArgumentError, "The IPOAlgorithm can process at most 26 parameters (at least 2 parameters must be provided)" if @no_parameters >26 || @no_parameters < 2
		raise ArgumentError, "The number of parameters doesn't match the size of the array argument representing the number of levels for each parameter." unless levels.size == @no_parameters
		raise ArgumentError, "The number of levels for each argument must be an Integer." unless levels.all? {|l| l.is_a? Integer}


		#initialization of the remaining instance_variables
		@levels = levels
		@runs = Array.new
		@parameters = Array.new
		@infeasible_pairs = Array.new

		#to differentiate values of different factors, each factor is named with uppercase letters in the range [A-Z]; thus the number of factors is limited to a maximum of 26 factors
		0.upto(@no_parameters-1) do |i|
			@parameters << Parameter.new((65 + i).chr, @levels[i])
		end

		#
		#reads the parameters and relative values from the csv file passed as an argument and checks if the number of factors and relative levels correspond to the specified values
		#if a .csv file containing the infeasible pairs is passed parses this file in order to check if the specified levels are valid and represents these values by means of the format used by the internal logic of the algorithm
		unless csv.nil?
			puts csv
			@actual_parameters = Array.new
			#parses the .csv file containing the factors and relative levels and saves the values in a tabular format
			read_parameters_from_csv(csv)
			#performs checks for inconsistencies
			raise ArgumentError, "The number of factors in the CSV file doesn't correspond to the specified value" unless @actual_parameters.size == @parameters.size
			@actual_parameters.each_with_index {|t,i| raise ArgumentError, "The number of levels doesn't correspond to the specified values" unless t.size - 1  == @levels[i]}
			#in case an additional file for the infeasible pairs is passed parses this file
			unless infeasible_csv.nil?
				#reads the infeasible pairs and stores them in the '@infeasible_pairs' instance variable
				read_infeasible_pairs(infeasible_csv)

				@infeasible_pairs.each_with_index do |p,i|
					#checks if the levels belonging to the pair exist and saves the 'a1', 'b3', ... internal representation using temporary variables
					temp1 = find_value p.first
					temp2 = find_value p.last

					#raises ArgumentError if the levels weren't specified in the factors' .csv file
					raise ArgumentError,"#{p.first} level specified in the #{infeasible_csv} file doesn't belong to any parameter in the #{csv} file" if temp1.nil?
					raise ArgumentError,"#{p.last} level specified in the #{infeasible_csv} file doesn't belong to any parameter in the #{csv} file" if temp2.nil?
					#overwrites the levels using the internal representation
					@infeasible_pairs[i] = [temp1,temp2]
					#orders the levels in alphabetically ascending order
					@infeasible_pairs[i].sort_by {|p| p}

				end
			end
		end

		#generate all pairs of the first two parameters F1 and F2 and add them to the runs

		@parameters[0].values.each do |value1|
			@parameters[1].values.each do |value2|
				@runs << (Run.new.elements << value1 << value2)
			end
		end

		#removes the infeasible pairs
		@runs -= @infeasible_pairs


		#possible termination if there are 2 factors
		return nil if no_parameters == 2

		#given that there are more than 2 factors there's need to repeat the next steps for all the remaining factors
		2.upto(no_parameters-1) do |current_F|
			#replace all runs with an extended version containing an appropriate value of the current parameter; keep track of the uncovered pairs
			temp = horizontal_growth(current_F)
			@runs = temp[:runs]
			uncovered_pairs = temp[:uncovered_pairs]

			#if there aren't any uncovered pairs end the current step else apply the vertical growth procedure
			@runs += vertical_growth(uncovered_pairs,current_F) unless uncovered_pairs.empty?
		end

		#displays the runs obtained by the algorithm in a generic form and, if a .csv file was provided, with real values
		format_output_without_CSV if csv.nil?
		format_output_with_CSV unless csv.nil?
		self
	end

	private

	def horizontal_growth(f)

		#calculate all the pairs formed by the values of already processed factors and those of the current factor
		ap = Array.new
		0.upto(f-1) {|i| ap += pairs(i,f)}

		#removes the infeasible pairs

		ap -= @infeasible_pairs

		#calculate the minimum between the number of tests already obtained and the number of levels of the current factor
		c = [@parameters[f].no_levels, @runs.size].min

		#the runs already obtained are extended with values of the current factor; the pairs contained by the runs thus extended, are removed from the ap (all pairs) set; given the fact that values of the factor can give rise to infeasible pairs the original IPO algorithm is thus modified:
		#for each run an attempt is made to extend the run with a different level of the factor under observation; the first level which hasn't been already used and that doesn't form infeasible pairs with the values contained by the run is added to the run; the 'loop_counter' variable serves as a flag to indicate if such a value is available; if it reaches 2 then it means that all the values have been examined and there isn't such a level
		#an already used level is used to extend the run; if all levels give rise to unfeasible pairs an error is raised indicating that the input to the algorithm cannot produce valid runs

		#saves the already used levels in order to minimize the number of tests
		already_used_level = []
		tPrime = Array.new
		0.upto(c-1) do |i|
			#the evaluation of levels of the current factor under observation starts at a specific index in accordance with the original IPO Algorithm, so that a minimal set of runs is obtained
			j=i
			loop_counter=0
			loop do
				#attempt to extend the run with the next level of the factor
				temp = ext(@runs[i].dup,@parameters[f].values[j])
				#if it doesn't form infeasible pairs and it hasn't been already used the run is extended with this level
				if (!pairs_for_run(temp).any? {|t| @infeasible_pairs.include? t} && !already_used_level.include?(j))
					tPrime << temp
					already_used_level << j
					break
				end
				#the parsing of the levels of the factor restarts with the first level in a circular fashion; the loop_counter flag is increased
				if j==@parameters[f].no_levels-1
					j=0
					loop_counter+=1
				else
					#increases the index that points at the next level of the factor
					j+=1
				end
				#if the domain of the factor has been parsed and no valid level was encountered stop the search
				break if loop_counter == 2
			end
			#search an already used level to extend the run in a similar fashion to the steps commented above; this time raise an error if no such level is found meaning that there is no valid run that respects the contraints of infeasible pairs
			j=i
			loop_counter_2 = 0
			if loop_counter==2
				loop do
					temp = ext(@runs[i].dup,@parameters[f].values[j])
					if (!pairs_for_run(temp).any? {|t| @infeasible_pairs.include? t})
						tPrime << temp
						break
					end
					if j==@parameters[f].no_levels-1
						j=0
						loop_counter_2+=1
					else
						j+=1
					end
					loop_counter_2
					raise ArgumentError,"The input provided doesn't allow the creation of valid runs(raised in horizontal_growth)" if loop_counter_2 == 2
				end
			end

			#remove the covered pairs by the run produced
			ap -= pairs_for_run(tPrime[i])
		end

		#if the minimum is the preexistent number of runs than the method return the extended runs
		return {runs: tPrime, uncovered_pairs: ap} if c == @runs.size

		#
		#otherwise extend the remaining runs by values of the current factor under observation that cover the maximum number of pairs in ap
		#

		valuePrime = nil
		apPrime = []

		#scan every run already produced
		c.upto(@runs.size-1) do |j|
			apSecond = []
			#for every value of the current factor under observation
			@parameters[f].values.each_with_index do |value,index|
				#extend the run with the value
				tempa = ext(@runs[j].dup,value)
				#check if any infeasible pairs have been obtained
				unless pairs_for_run(tempa).any? {|p| @infeasible_pairs.include? p}
					#calculate the pairs contained by the run thus obtained
					apSecond = pairs_for_run(tempa)
					#find the value that adds the maximum pairwise coverage
					if apSecond.find_all {|e| ap.include? e}.size > apPrime.find_all {|e| ap.include? e}.size
						apPrime = apSecond
						valuePrime = value
					end
				end
				raise ArgumentError,"The input provided doesn't allow the creation of valid runs(raised in horizontal_growth)" if apSecond.nil? && index == @parameters[f].no_levels-1
			end
			#extend the run with the value found in the previous step
			tPrime << ext(@runs[j].dup,valuePrime)
			#remove the pairs covered by the newly extended run
			ap -= apPrime
		end
		{runs: tPrime, uncovered_pairs: ap}
	end

	#
	#permits to extend a run with a value
	#
	def ext(run, val)
		run << val
	end

	#
	#given the indexes for two parameters produces the cartesian product of their respective values
	#
	def pairs(f1, f2)
		temp = Array.new
		@parameters[f1].values.each do |value1|
			@parameters[f2].values.each do |value2|
				temp << (Run.new.elements << value1 << value2)
			end
		end
		temp
	end

	#
	#produces all the pairs of values given a run
	#
	def pairs_for_run(run)
		temp = Array.new
		0.upto(run.size-2) do |index1|
			(index1+1).upto(run.size-1) do |index2|
				temp << ([] << run[index1] << run[index2])
			end
		end
		temp
	end

	#
	#Vertical Growth procedure to produce additional runs that cover the remaining uncovered pairs
	#
	def vertical_growth(uncovered_pairs,current_F)
		current_F = current_F
		tPrime = []
		#scan every run
		uncovered_pairs.each do |u_pair|
			#calculate the index of the factor whose value doesn't form any pair with the factor under observation within the preexistent runs
			uncovered_F = u_pair[0][0].ord - 97
			#use the flag to indicate if the pair has been covered
			flag = false
			#scan every preexistent run
			@runs.each do |run|
				#if the run contains a placeholder to indicate the absence of a value where a value of the factor with index uncovered_F should be, overwrite the placeholder with the uncovered value
				temp = run.dup
				temp[uncovered_F] = u_pair[0]
				if run[uncovered_F].nil? && !pairs_for_run(temp).any? {|p| @infeasible_pairs.include? p}
					run[uncovered_F] = u_pair[0]
					#indicate that the pair is covered and break the loop
					flag = true
					break
				end
			end

			#if no placeholder was found create a new run
			if !flag
				temp = []
				0.upto(current_F-1) do |j|
					#use placeholders for values belonging to factors different from the one whose value isn't covered (uncovered_F)
					if j != uncovered_F
						temp << nil
					#save the value needing coverage
					else
						temp << u_pair[0]
					end
				end
				#append the second value of the uncovered pair, that belongs to the factor under observation (current_F)
				temp << u_pair[1]
				#add the run obtained to the set of runs
				tPrime << temp
			end
		end
		#
		#replace each placeholder with a value of the corresponding factor selected in random fashion but respecting the constraints on infeasible pairs
		#
		#for each run obtained in the previous step
		tPrime.each do |run|
			#for each level of the run
			run.each_with_index do |val,index|
				#if the value is nil
				if run[index].nil?
					#create a copy of the run
					temp = run.dup
					#generate a random index in the range that goes from zero to the number of levels of the factor - 1
					i = rand(0...@parameters[index].no_levels)
					#store this index
					j = i
					loop do
						#check if the level at index j is a valid one in the sense that doesn't form infeasible pairs
						temp[index] = @parameters[index].values[j]
						#if it's valid stop the search
						break unless pairs_for_run(temp).any? {|p| @infeasible_pairs.include? p}
						#tries next level
						j+=1
						#if it reaches the last level of the factor restart from the first level in a circular fashion
						j = 0 if j == @parameters[index].no_levels
						#if no level is valid raise an exception
						raise ArgumentError,"The input provided doesn't allow the creation of valid runs(raised in vertical_growth)" if j == i
					end
					#save the level thus obtained
					run[index] = temp[index]
				end
			end
		end
		#return the runs obtained by the Vertical_Growth method
		tPrime
	end

	#
	#formats the runs obtained by the algorithm in a table with an appropriate structure
	#
	def format_output_without_CSV
		headings = [] << "Run"
		rows = []
		@parameters.each_with_index {|p,i| headings << "F#{i+1}"}
		@runs.each_with_index {|r,i| temp = ["#{i+1}"]; temp += r; rows << temp}
		@output_table = Terminal::Table.new :title => "IPO Algorithm tests output", :headings => headings, :rows => rows
	end

	#
	#formats the runs obtained by the algorithm substituting real values passed by means of the .csv file
	#

	def format_output_with_CSV()
		headings = [] << "Run"
		rows = []
		@actual_parameters.each {|t| headings << t[0]}
		@runs.each_with_index do |run,i|
			temp = ["#{i+1}"];
			run.each_with_index do |r,i|
				temp << @actual_parameters[i][Integer(run[i][1])]
			end
			rows << temp
		end
		@output_table = Terminal::Table.new :title => "IPO Algorithm tests output", :headings => headings, :rows => rows
	end

	#
	#the procedure reads the .csv file and produces a tabular representation
	#
	def read_parameters_from_csv(csv)
		begin
			temp = CSV.read(csv)
		rescue Exception
			raise ArgumentError, "It wasn't possible to read from #{csv} file."
		end
		temp.each_with_index do |row,index|
			@actual_parameters[index] = row[0].split(';')
		end
	end

	#
	#reads the infeasible pairs from the .csv file
	#
	def read_infeasible_pairs(infeasible_csv)
		begin
			temp = CSV.read(infeasible_csv)
		rescue Exception
			raise ArgumentError, "It wasn't possible to read from #{infeasible_csv} file."
		end
		temp.each_with_index do |row,index|
			@infeasible_pairs[index] = row[0].split(';')
		end
		raise ArgumentError,"Every line of the .csv file containing infeasible pairs must contain exactly 2 elements" unless @infeasible_pairs.all? {|pair| pair.size == 2}
	end

	#permits to retrieve a level from the tabular representation of the .csv file of factors; if it exists the internal representation of the level is returned, consisting of a lowercase letter from a to z and an index
	def find_value(val)
		temp = nil
		@actual_parameters.each_with_index do |row,index|
			row.each_with_index do |element, index1|
				if (element.downcase.delete(' ') == val.downcase.delete(' ') && index1 != 0)
					return (index + 97).chr + index1.to_s
				end
			end
		end
		return nil
	end
end

require_relative 'IPOAlgorithm/Parameter'
require_relative 'IPOAlgorithm/Run'
