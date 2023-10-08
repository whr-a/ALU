#!/bin/bash

iverilog -o my_design.out float-user.v
vvp my_design.out