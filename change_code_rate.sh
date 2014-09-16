#!/bin/bash

# Author: chibby0ne

# check that there is one argument
if [[ $# -eq 1 ]]; then

    # check if it is a valid code rate
    if [[ $1 = "R050" || $1 = "R062" || $1 = "R075" || $1 = "R081" ]]; then

        if [[ $1 = "R050" ]]; then
            P="00"
        elif [[ $1 = "R062" ]]; then
            P="01"
        elif [[ $1 = "R075" ]]; then
            P="10"
        else
            P="11"
        fi

        # get only the code rate value 
        V=${1:1}

        # substitute in any case it may be
        sed -i "s/0[0-9][0-9]\_/$V\_/g" testbench/tb_top_level.vhd              # inputoutput files
        sed -i "s/0[0-9][0-9]\;/$V\;/g" testbench/tb_top_level.vhd             # code rate variable

        # for wrapper
        sed -i "s/0[0-9][0-9]\_/$V\_/g" testbench/tb_top_level_wrapper.vhd      # input/output files
        sed -i "s/\"[0-1][0-1]/\"$P/g" testbench/tb_top_level_wrapper.vhd    # code rate variable


    else
        echo "Error. $1 is not a valid code rate"
    fi
else
    echo "Usage is ./script CODERATE 
where CODERATE is either R050, R062, R075 or R081"
fi
