# Load the required packages
using CSV, DataFrames, JuMP, Gurobi, Plots, StatsPlots, GLPK
using Printf, XLSX , LinearAlgebra, Plots, Plots.PlotMeasures

# # include("filepath to_your_functions.jl")
# Example usage:
# include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Decoupled_OPF_Functions/get_data_Decoupled.jl")
# include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Decoupled_OPF_Functions/create_matrices_Decoupled.jl")
# include("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Decoupled_OPF_Functions/get_functions_Decoupled.jl")
include(".../Decoupled_OPF_Functions/get_data_Decoupled.jl")
include(".../Decoupled_OPF_Functions/create_matrices_Decoupled.jl")
include(".../Decoupled_OPF_Functions/get_functions_Decoupled.jl")

# # Load the input data
# Choose input filename and path
# Example usage:
# filename = "case_ieee123_modified.xlsx"
# load_power_system_data_decoupled_opf(
#     "/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files", 
#     filename,
#     Ssystem=1
# )
filename = "file name of the system studied.xlsx"
load_power_system_data_thesis_linear_opf("Filepath to your system studied", 
filename,
Ssystem=1)


case = splitext(filename)[1] 
println("Case name: ", case)

# # Create the bus matrices (mapped Y and B matrix)
create_admittance_matrix_decoupled_opf()
println("Sample Y matrix element: ", Y[1,1])
println("Sample B matrix element: ", B[1,2])


# # Choose solver
solver = "gurobi"
# # Create the OPF model and solve the Decoupled OPF problem
Decoupled_OPF_model = create_decoupled_opf_problem()
# # Objective value
println("Objective value: ", objective_value(Decoupled_OPF_model))

# # Output file path
#setup_results_path("Output folder name", "Output file name.xlsx")
# Example usage:
# setup_results_path("Results_Decoupled", "Decoupled_OPF_Results.xlsx")
setup_results_path("", "")

# # Printing the results
create_decoupled_opf_results(Decoupled_OPF_model)

#################################################### CREATE PLOTS ####################################################
create_active_plot_Decoupled(production_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_reactive_plot_Decoupled(production_df,OUTPATH, case;zoom_out=-0.3, yticks_range=0:0.5:4)

create_voltage_magnitude_plot_Decoupled(results_df,OUTPATH, case;zoom_out=2, yticks_range=0:1:3)

create_voltage_angles_plot_Decoupled(results_df,OUTPATH, case;zoom_out=2, yticks_range=-20:0.5:3)

create_nodal_prices_plot_Decoupled(price_df,OUTPATH, case;zoom_out=11, yticks_range=5:2:40)