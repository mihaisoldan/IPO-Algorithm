Gem::Specification.new do |s|
  s.name               = "IPOAlgorithm"
  s.version            = "0.0.0"
  s.default_executable = "IPOAlgorithm"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mihai Soldan"]
  s.date = %q{2016-07-27}
  s.description = %q{IPO (In-Parameter-Order) procedure for the generation of mixed level covering arrays with constraints of infeasible pairs.}
  s.email = %q{catalinmihai.soldan@studenti.unicam.it}
  s.files = ["Rakefile","lib/IPOAlgorithm.rb", "lib/IPOAlgorithm/Parameter.rb", "lib/IPOAlgorithm/Run.rb", "bin/IPOAlgorithm.rb", "test/test_IPOAlgorithm.rb","test/incorrect_file.csv","test/input_file_impossible_combination_VG.csv","test/input_file_impossible_combination_HG.csv","test/input_file.csv","test/infeasible_pairs_unspecified_level.csv","test/infeasible_pairs_not_all_pairs.csv","test/infeasible_pairs_impossible_combination_VG.csv","test/infeasible_pairs_impossible_combination_HG.csv","test/infeasible_pairs.csv"]
  s.test_files = ["test/test_IPOAlgorithm.rb"]
  s.homepage = %q{http://rubygems.org/gems/IPOAlgorithm}
  s.require_paths = ["lib"]
  s.summary = %q{IPO procedure}
  s.license       = 'GNU GPLv3'
  s.add_runtime_dependency 'terminal-table', '1.6.0'
  
end