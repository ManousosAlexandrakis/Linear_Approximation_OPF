<h1 align="center">
  A Linear Approximation for the Optimal Power Flow Problem 
</h1> 




<p align="center">
  <a href="https://github.com/ManousosAlexandrakis/Linear_Approximation_OPF" title="Linear_Approximation_OPF">
    <img alt="Linear_Approximation_OPF" src="https://www.ece.ntua.gr/themes/ecetheme/assets/img/pyrforos.svg" width="200px" height="200px" />
  </a>
</p>

![Static Badge](https://img.shields.io/badge/Julia_version-1.11.4-green)

## Repository's purpose
This repository contains a linear model for the approximation of the Optimal Power Flow (OPF) problem, developed as part of my diploma thesis under the supervision of [Prof. Anthony Papavasiliou](https://ap-rg.eu/) and ZeJun Ruan. It includes implementation code, case files in XLSX format, and code for plotting results. Additionally, implementation code for DCOPF Bθ and Decoupled OPF models is included.

## Authors
This code was created by [Manousos Alexandrakis](https://github.com/ManousosAlexandrakis), [Lina Efthymiadou](https://github.com/lina-efthymiadou), [ZeJun Ruan](https://github.com/zejunr), listed in alphabetical order. The initial work was carried out by ZeJun Ruan and Lina Efthymiadou, while Manousos Alexandrakis finalized the implementation.

For any questions or contributions, feel free to open an issue or submit a pull request.

## Files Explanation

- **Linear_OPF_Final**: Generates results for the proposed linear model.  
- **OPF_Decoupled**: Generates results for the decoupled model.  
- **DCOPF_BTheta**: Generates results for the BTheta model.  
- **Plotting_Scripts**: Creates visualizations for all models (including the ACOPF model, which is not included in this repository).  
- **Case_Files**: Contains input data for one energy system.  


## Simple Instructions
To run this project, you’ll need to have the Julia programming language installed, along with a few required packages. Although any IDE will work, this project was developed using Visual Studio Code with the Julia extension.

### Setup Steps
1. **Install Julia:** 
Download and install [Julia application](https://julialang.org/downloads) 

2. **Open the Project in VS Code (or your preferred IDE):**
Make sure you have the Julia extension installed in VS Code for best support.

3. **Install Required Packages:**
Open the Julia REPL (terminal) in VS Code, then enter package mode by typing:
```
]
```
Then, install the necessary packages by typing:
```
add PackageName
```
Replace **`PackageName`** with each package required for this project (e.g. Plots, JuMP, etc.).

4. **Install an Optimizer**

This project uses the **Gurobi Optimizer**, a powerful commercial solver. To use Gurobi, make sure you have:

- A valid **Gurobi license** (Free academic licenses are available)
- The **[Gurobi application](https://www.gurobi.com/downloads/gurobi-software/)** installed on your system
- The **Gurobi Julia package** added to your environment (add Gurobi package as shown in step 3)

To install the package in Julia, open the Julia REPL and enter:

```julia
] add Gurobi
```
#### Note: Using Gurobi in Your Code

After installing Gurobi, you can initialize and use it as your solver with the following setup:

```julia
# Create a mathematical optimization model using the Gurobi Optimizer as the solver
GUROBI_ENV = Gurobi.Env()
model = Model(() -> Gurobi.Optimizer(GUROBI_ENV))
set_optimizer_attribute(model, "MIPGap", 0.0) 
set_silent(model)
```


If you prefer a free and open-source alternative, you can use GLPK instead. It works well for most linear optimization problems. Install GLPK with:
```
] add GLPK
```

### How to Run the Code
To ensure the code files run correctly, you must load the case files properly. There are two ways to do this:

1. **Use the full file path**  
2. **Use only the filename** (This works only if the case file is in the same directory as the code file.)

:warning: **Important note:** The format of file paths differs between operating systems. The examples shown are based on macOS; Windows users should adjust the paths accordingly (e.g., use double backslashes \ \ instead of forward slashes /).  
### Example:
![How to read input XLSX file](Resources/input_code_format.png)

The same approach applies to the output data XLSX file. 
### Example:
![How to write output XLSX file](Resources/output_code_format.png)

Make sure that the input case files follow the same formatting as the examples provided in the [`Case_Files`](./Case_Files) folder.


If the above steps are followed correctly, the code file should run without issues—only infeasibility could cause an error.



## Plotting Scripts  

This folder contains scripts for generating visualizations from the code's output data.

### How to Plot: Step-by-Step
1. Make sure you load input data in the right way
#### Example for input 
![How to read input XLSX file for plot](Resources/input_code_for_plots.png)

2. Some parameters may require adjustment for optimal display:  

- **`yticks`** – Adjust if y-axis labels are poorly spaced or unclear.  
- **`zoom_out`** – Modify to control the zoom level of the plot.

### 📊 Plotting Example:
<p align="center">
  <img src="Resources/Example_Plotting.gif" alt="Demo Animation" width="1000"/>
</p>

After saving the figure as a PDF, it will look like this:


<p align="center">
  <img src="Example_Plots/paper_pv_active_V3-1.png" alt="View Saved Figure (PNG)" width="500"/>
</p>

More plotting examples can be found in the [`Example_Plots`](./Example_Plots) folder.


3. Make sure to save the plot to your desired folder with a filename of your choice.

#### Example for plot saving:
![How to save plot](Resources/ouput_code_for_plots.png)




#### 📌 Notes  
- Ensure the input data is in the correct format before running.  
- Fine-tune parameters as needed for different datasets. 
- The palette used can be viewd here: https://www.color-hex.com/color-palette/894  



