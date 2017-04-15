# IPOAlgorithm
In-Parameter-Order, or simply IPO, procedure. It takes the number of factors and the corresponding levels as inputs and generates a covering array that is, at best, near optimal. The covering array generated covers all pairs of input parameters at least once and is used for generating tests for pairwise testing.


## Code Example

The algorithm in its basic form takes as input the number of parameters and the number of levels for each parameter.

```ruby
ipo = IPOAlgorithm.new 3,[3,5,5]
puts ipo.output_table
```
![alt tag](https://github.com/mihaisoldan/IPOAlgorithm/blob/master/examples/example1.jpg)

******

By providing a .csv file with actual values for the parameters such as this (*input_file.csv*): (the table has been transposed for markdown syntax reasons) 

| Hardware              | OS                                       | Browser             |
|-----------------------|------------------------------------------|---------------------|
| Dell Dimension Series | Windows Server 2008: Web Edition         | Internet Explorer 9 |
| Apple iMac            | Windows Server 2008: R2 standard edition | Internet Explorer   |
| Apple MacBook Pro     | Windows 7 Enterprise                     | Chrome              |
|                       | OS 10.6                                  | Safari 5.1.6        |
|                       | OS 10.7                                  | Firefox             |


```ruby
ipo = IPOAlgorithm.new 3,[3,5,5], "input_file.csv"
puts ipo.output_table
```
![alt tag](https://github.com/mihaisoldan/IPOAlgorithm/blob/master/examples/example2.png)

******

It is also possible to provide a .csv file containing infeasible pairs such as this (*infeasible_pairs.csv*):

| Level1                                   | Level2                                   |
|------------------------------------------|------------------------------------------|
| Dell Dimension Series                    | OS 10.6                                  |
| Dell Dimension Series                    | OS 10.7                                  |
| Apple iMac                               | Windows Server 2008: Web Edition         |
| Apple iMac                               | Windows Server 2008: R2 standard edition |
| Apple iMac                               | Windows 7 Enterprise                     |
| Apple MacBook Pro                        | Windows Server 2008: Web Edition         |
| Apple MacBook Pro                        | Windows Server 2008: R2 standard edition |
| Apple MacBook Pro                        | Windows 7 Enterprise                     |
| Dell Dimension Series                    | Safari 5.1.6                             |
| Apple iMac                               | Internet Explorer 9                      |
| Apple iMac                               | Internet Explorer                        |
| Apple MacBook Pro                        | Internet Explorer 9                      |
| Apple MacBook Pro                        | Internet Explorer                        |
| OS 10.6                                  | Internet Explorer 9                      |
| OS 10.6                                  | Internet Explorer                        |
| OS 10.7                                  | Internet Explorer 9                      |
| OS 10.7                                  | Internet Explorer                        |
| Windows Server 2008: Web Edition         | Safari 5.1.6                             |
| Windows Server 2008: R2 standard edition | Safari 5.1.6                             |
| Windows 7 Enterprise                     | Safari 5.1.6                             |

```ruby
ipo = IPOAlgorithm.new 3, [3,5,5], "input_file.csv", "infeasible_pairs.csv" 
puts ipo.output_table
```
![alt tag](https://github.com/mihaisoldan/IPOAlgorithm/blob/master/examples/example3.png)


## Motivation

The idea behind this project is to make the original IPO procedure of practical use. In its original form it doesn't take into account any infeasible pairs and generates tests capable of covering all possible pairs. The algorithm respects the efficiency of the original version, i.e. the number of runs generated is minimal, and extends its functionality with the specification of infeasible pairs.

## Installation

gem install IPOAlgorithm


## Tests

```bash
ruby test/test_IPOAlgorithm.rb
```
The tests use the two .csv files presented above and modified versions that introduce errors that are to be captured by the algorithm.
For just the covering capability of the algorithm (without specification of infeasible pairs) tests are generated automatically for up to a specified number of parameters (default value is set to 10). (for a thorough description of the tests check *test_IPOAlgorithm.rb*)

## Contributors

The project is an assignment I did for a Software Testing course I'm following at my university. If anyone is interested in contributing don't hesitate.

## License

A short snippet describing the license (MIT, Apache, etc.)
