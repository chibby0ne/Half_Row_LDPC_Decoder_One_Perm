### VHDL implementation of a Half-row Layered LDPC Decoder using "one permutation" Offset Matrix for standard IEEE 802.11ad 

* Based on [this paper](https://github.com/chibby0ne/modifications/blob/master/doc/06674490.pdf). Also available from [IEEE](http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6674490)
* Implements all 4 code rates
* *"one permutation"* - it doesn't really use one but two permutation networks because it is needed to support all code rates, but one of them has smaller activity factor than a normal operation permutation network, because it uses offsets instead of shifts. For more information see [this other paper](https://github.com/chibby0ne/modifications/blob/master/doc/05439945.pdf) or from [IEEE](http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5439945)

#### do_files
* *script_top.do* - compiles everything needed for top_level
* *script_top_wrapper.do* - compiles everything for top_level_wrapper (used in synthesis and p&r)
* *sim_top_level.do* - adds a lot of signals to wave and simulates until end of input (for top level)
* *sim_top_level_quick.do* - adds a few signals to wave and simulates until end of input (for top level)
* *sim_top_level_wrapper.do* - adds a lot of signals to wave and simulates until end of input
* *sim_top_level_wrapper_quick.do* - adds a few signals to wave and simulates until end of input (for top level)

#### script
* *create input file.sh* - creates input files formated for use in testbench out of the simulation chain. Of course, you have to make some modifications to simulation chain
* *change_code_rate.sh* - changes the input and output file and code rate used in the both testbench files for top_level and top_level wrapper depending on the given code rate

#### input_files
* contains input files for each code rate and has two version of each file: one taken from the simulation chain and another in a column format used by testbenches

#### output files
* contains output files for each code rate and has two version of each file: one taken from the simulation chain and another in a column format used by testbenches

#### pkg
* contains packages

#### src
* contains sources

#### testbench
* contains... you guessed it?
