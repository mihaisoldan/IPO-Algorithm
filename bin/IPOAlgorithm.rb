require_relative '../lib/IPOAlgorithm.rb'

#
#Exception handling for the arguments passed to the algorithm
#

#The algorithm raises an error if the number of arguments is not 2
raise ArgumentError, "The IPO algorithm needs at least 2 arguments and a maximum of 4." unless 2 <= ARGV.size && ARGV.size <=4

#The first argument must be an integer indicating the number of factors/parameters
raise ArgumentError, "The first parameter must be an Integer i s.t. 2 <= i <= 26 indicating the number of factors." unless (no_parameters = Integer(ARGV.first)) && no_parameters >= 2 && no_parameters < 27

#The second argument must be an array that is matched against a regular expression to see if it is of the correct form
raise ArgumentError, "The second parameter must be an array of form [val1, val2, ... valn] where each vali indicates the number of levels for factor i and n is the number of factors already specified as the first parameter to the algorithm." unless /\[(\d+,)+\d+\]/.match ARGV[1]

#The 'levels' array will contain the number of values (levels) for each parameter 
levels = eval ARGV[1]
raise ArgumentError, "The second parameter must be an array of form [val1, val2, ... valn] where each vali indicates the number of levels for factor i and n is the number of factors already specified as the first parameter to the algorithm." if levels.size != no_parameters

puts IPOAlgorithm.new(no_parameters, levels,ARGV[2],ARGV[3]).output_table

