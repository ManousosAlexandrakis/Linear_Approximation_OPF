# Linear_Approximation_OPF

Repository's purpose:
This repository contains a linear model for the approximation of Optimal Power Flow (OPF) problem, developed as part of my diploma's thesis. It includes implementation code, case files in XLSX format and code for plotting results. Also, implementation code for DCOPF and Decoupled OPF is included.

## Authors
This code was created by [Manousos Alexandrakis](https://github.com/ManousosAlexandrakis),[]().

For any questions or contributions, feel free to open an issue or submit a pull request.

## Files Explanation

- **Linear_OPF**: Generates results for the proposed linear model.  
- **Decoupled_OPF**: Generates results for the decoupled model.  
- **DCOPF_BTheta**: Generates results for the BTheta model.  
- **Plots**: Creates visualizations for all models (including the ACOPF model, which is not included in this repository).  
- **Case_Files**: Contains input data for four different energy systems.  


## Simple Instructions

To ensure the code files run correctly, you must load the case files properly. There are two ways to do this:

1. **Use the full file path**  
2. **Use only the filename** (This works only if the case file is in the same directory as the code file.)  

The same approach applies to the output data XLSX file.  

Make sure that the input case files follow the same formatting as the examples provided in the `Case_Files` folder.


If the above steps are followed correctly, the code file should run without issues—only infeasibility could cause an error.

## Plotting Adjustments

The provided plotting code may require some adjustments to produce the desired results. Depending on the case file, modifications might be necessary. Specifically, `yticks_values_production` and `ylim` must be set to the same values to ensure proper scaling of the y-axis.  

Additionally, the files are loaded using their file paths in the given code—following the same approach should ensure smooth execution.

