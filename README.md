# Linear_Approximation_OPF

Repository's purpose:
This repository contains a linear model for the Optimal Power Flow (OPF) problem, developed as part of my diploma's thesis. It includes implementation code, case files in XLSX format, and code for plotting results. Also, implementation code for DCOPF and Decoupled OPF is included.

## Authors
This code was created by [Manousos Alexandrakis](https://github.com/ManousosAlexandrakis),[]().

For any questions or contributions, feel free to open an issue or submit a pull request.

## Files Explanation
- Linear_OPF generates the results of the proposed model
- Decoupled OPF generates the results of the Decoupled model
- DCOPF_BTheta generates the results of the BTheta model
- Plots generates the plots for all the models (it includes ACOPF model which is not in the repository)
- Case files' folder contains the input data for 4 different energy systems

## Simple Instructions
In order to run the code files correctly you have to check that you load the case files in the right way. There are two ways to do so:
1. Use the filepath
2. Use only the filename (for this to work the casefile must be in the same directory as the codefile)

In the same manner can be treated the output data xlsx file.

Be sure that the input case files that are used have the same formatting as the given in Case_Files folder.
If the above steps are followed correctly, the code file should run without issues—only infeasibility could cause an error.

The code given for plotting maybe be a little more trickier to give the results you wwant. Depending on the case file there will be needs for changes in the code. yticks_values_production and ylim must have the same values. You need to change these values in order to adjust the values of y-axis.
