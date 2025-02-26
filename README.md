# Linear_Approximation_OPF

## Repository purpose
This repository contains a linear model for the approximation of the Optimal Power Flow (OPF) problem, developed as part of my diploma thesis under the supervision of [Anthony Papavasiliou](https://ap-rg.eu/) and [Zejun Ruan](https://github.com/zejunr). It includes implementation code, case files in XLSX format, and code for plotting results. Additionally, implementation code for DCOPF and Decoupled OPF is included.

## Authors
This code was created by [Manousos Alexandrakis](https://github.com/ManousosAlexandrakis), [Lina Efthymiadou](https://github.com/lina-efthymiadou), [Zejun Ruan](https://github.com/zejunr), listed in alphabetical order. The initial work was carried out by Zejun Ruan and Lina Efthymiadou, while Manousos Alexandrakis finalized the implementation.

For any questions or contributions, feel free to open an issue or submit a pull request.

## Files Explanation

- **Linear_OPF_Final**: Generates results for the proposed linear model.  
- **OPF_Decoupled**: Generates results for the decoupled model.  
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

The provided plotting code may require some adjustments to produce the desired results. Depending on the case file, modifications might be necessary. Specifically, `upper`, `lower` and `length` must be set to proper values to ensure correct scaling of the y-axis.  

Additionally, the files are loaded using their file paths in the given code—following the same approach should ensure smooth execution.

