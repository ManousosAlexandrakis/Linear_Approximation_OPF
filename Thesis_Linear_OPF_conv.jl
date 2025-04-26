# Load the required packages
using CSV, DataFrames, JuMP, Gurobi, Plots, StatsPlots
using Printf, XLSX
using Plots
using Plots.PlotMeasures
using LinearAlgebra


# include("filepath to_your_functions.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Thesis_Linear_OPF_Functions/get_data_Thesis_Linear.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Thesis_Linear_OPF_Functions/mapping_and_matrices_creation_Thesis_Linear.jl")
include("/Users/malexandrakis/Documents/Οικονομική και Αξιόπιστη/Thesis_Linear_OPF_Functions/get_functions_Thesis_Linear.jl")

# ADD INPUT FILENAME AND FILEPATH
# # Load the input data
filename = "case_ieee123_modified.xlsx"
load_power_system_data_thesis_linear_opf("/Users/malexandrakis/Library/CloudStorage/OneDrive-Personal/Diploma_Thesis/Linear_Approximation_OPF/Case_Files", 
    filename,
    Ssystem=1)


case = splitext(filename)[1] 
println("Case name: ", case)

# # Create the bus matrices (mapped Y, mapped Z matrix and the submatrices of Z matrix)
create_bus_matrices()

# # CHOOSE SOLVER
solver = "gurobi"

# # Create the OPF model and solve the Linear OPF problem
Linear_Thesis_OPF_model = create_opf_model()
# # Objective value
println("Objective value: ", objective_value(Linear_Thesis_OPF_model))

# # Output file path
#OUTPATH = "" # Name the folder for the results
OUTPATH = "Results_Thesis_Linear" 

# Create the output folder if it doesn't exist
if !ispath(OUTPATH)
    mkpath(OUTPATH)
    println("New directory created: ", OUTPATH)
end

# CHOOSE output_file_name = "example.xlsx"
ouput_file_name = "Thesis_Linear_OPF_Results.xlsx"

results_path = joinpath(pwd(), OUTPATH, ouput_file_name)

println("Results path: ", results_path)

# # Printing the results
create_results_dataframes(Linear_Thesis_OPF_model)



######################################################################################################################
#################################################### CREATE PLOTS ####################################################
######################################################################################################################
# # Create plot for the Active Power Production
create_active_plot_Thesis_Linear(prod_df,OUTPATH, case;zoom_out=0.5, yticks_range=0:1:3)

# # Create plot for the Reactive Power Production

#create_reactive_plot_Thesis_Linear(df_name,write OUTPATH, write case;zoom_out= write a positive value, yticks_range=ymin:ystep:ymax)
create_reactive_plot_Thesis_Linear(Qreact_df,OUTPATH, case;zoom_out=-0.19, yticks_range=-0.2:0.2:2)

# # Create plot for the Voltage Magnitude 

#create_reactive_plot_Thesis_Linear(df_name,OUTPATH, "name of the system studied";zoom_out=negative value, yticks_range=ymin:ystep:ymax)
create_voltage_magnitude_plot_Thesis_Linear(results_df,OUTPATH, case;zoom_out=0.2, yticks_range=0.8:0.02:1.2)

# # Create plot for the Voltage Angles

create_voltage_angles_plot_Thesis_Linear(results_df,OUTPATH, case;zoom_out=0.2, yticks_range=-20:1:0.2)

# # Create plot for the Nodal Prices

create_nodal_prices_plot_Thesis_Linear(price_df,OUTPATH, case;zoom_out=11, yticks_range=5:2:31)