using Plots
using Plots.PlotMeasures
using DataFrames
using LinearAlgebra,Dates
using XLSX, Printf


# # Set the file paths and load data
#  filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV"
#  filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
#  filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
#  filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
#  filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
#  filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")

# filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV/"
# filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
# filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
# filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
# filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
# filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")
# filename6 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV_fixed_active.xlsx")

filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV/"
filename1 = joinpath(filepath1,"AC_results_case_ieee123_python.xlsx")
filename3 = joinpath(filepath1,"BTheta_results_case_ieee123_python.xlsx")
filename4 = joinpath(filepath1,"Decoupled_results_case_ieee123.xlsx")
filename5 = joinpath(filepath1,"Bolognani_results_case_ieee123_python.xlsx")



#   filepath1 = "/Users/malexandrakis/Documents/Results/ehv1"
#   filename1 = joinpath(filepath1,"ACOPF_ehv1.xlsx")
#   filename2 = joinpath(filepath1,"ACOPF_ehv1_fixed.xlsx")
#   filename3 = joinpath(filepath1,"BTheta_ehv1.xlsx")
#   filename4 = joinpath(filepath1,"Decoupled_ehv1.xlsx")
#   filename5 = joinpath(filepath1,"LINEAR_OPF_ehv1.xlsx")


#     filepath1 = "/Users/malexandrakis/Documents/Results/ehv5"
#     filename1 = joinpath(filepath1,"ACOPF_ehv5.xlsx")
#     filename2 = joinpath(filepath1,"ACOPF_ehv5_fixed.xlsx")
#     filename3 = joinpath(filepath1,"BTheta_ehv5.xlsx")
#    filename4 = joinpath(filepath1,"Decoupled_ehv5.xlsx")
#     filename5 = joinpath(filepath1,"LINEAR_OPF_ehv5.xlsx")

    # filepath1 = "/Users/malexandrakis/Documents/Results/ehv4"
    # filename1 = joinpath(filepath1,"ACOPF_ehv4.xlsx")
    # filename2 = joinpath(filepath1,"ACOPF_ehv4_fixed.xlsx")
    # filename3 = joinpath(filepath1,"BTheta_ehv4.xlsx")
    # filename4 = joinpath(filepath1,"Decoupled_ehv4.xlsx")
    # filename5 = joinpath(filepath1,"LINEAR_OPF_ehv4.xlsx")


base_name = basename(filepath1) 

##################################################################################
VD_ACOPF_df = DataFrame(XLSX.readtable(filename1, "Results"))
#VD_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2, "Results"))
VD_BTheta_df = DataFrame(XLSX.readtable(filename3, "Results"))
VD_Decoupled_df = DataFrame(XLSX.readtable(filename4, "Results"))
VD_LINEAR_df = DataFrame(XLSX.readtable(filename5, "Results"))
#VD_LINEAR_fixed_df = DataFrame(XLSX.readtable(filename6, "Results"))
##################################################################################
Y_D_ACOPF = VD_ACOPF_df[!, "va_degrees"]
#Y_D_ACOPF_fixed = VD_ACOPF_fixed_df[!, "va_degrees"]
Y_D_BTheta = VD_BTheta_df[!, "va_degrees"]
Y_D_Decoupled = VD_Decoupled_df[!, "va_degrees"]
Y_D_LINEAR = VD_LINEAR_df[!, "va_degrees"]
#Y_D_LINEAR_fixed = VD_LINEAR_fixed_df[!, "va_degrees"]

# #  https://www.color-hex.com/color-palette/894 <-- The colour palette 

# # y_range
max_delta = maximum([maximum(Y_D_ACOPF), maximum(Y_D_BTheta), maximum(Y_D_Decoupled), maximum(Y_D_LINEAR)])
min_delta = minimum([minimum(Y_D_ACOPF), minimum(Y_D_BTheta), minimum(Y_D_Decoupled), minimum(Y_D_LINEAR)])

# max_delta = maximum([maximum(Y_D_ACOPF), maximum(Y_D_ACOPF_fixed), maximum(Y_D_LINEAR_fixed), maximum(Y_D_LINEAR)])
# min_delta = minimum([minimum(Y_D_ACOPF), minimum(Y_D_ACOPF_fixed), minimum(Y_D_LINEAR_fixed), minimum(Y_D_LINEAR)])
y_min = min_delta
y_max = max_delta
y_median = (y_min + y_max)/2
y_range = y_max - y_min

# # Data preparation
buses = VD_ACOPF_df.Bus
bus_count = length(buses)

# # Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_V = 0:1:bus_count+20
xticks_values_D = 0:5:bus_count
xticks_labels_D = buses_str[1:5:end]

# # Adjust zoom_out and yticks for better results
zoom_out = 0.4
ylim = (y_median - abs((y_range+ zoom_out)/2), y_median + abs((y_range+ zoom_out)/2))
fz = 18 

Delta = scatter(buses_str,
         Y_D_ACOPF,
         ylim = (y_median - abs((y_range+ zoom_out)/2), y_median + abs((y_range+ zoom_out)/2)),
         xlim = (0,bus_count),
         xlabel = "Buses",
         ylabel = "Delta[°]",
         #title = "Voltage Angle",
         legend = :topright,
         label = "ACOPF",
         markersize = 11,
         color = RGB(237/255,201/255,81/255),  # Color for the dataset
         alpha = 1,
         markerstrokewidth = 0,
         yticks = -18:0.5:2,
         xticks = (xticks_values_D,xticks_labels_D),  # Set xticks and labels
         markershape = :circle,
         size = (2000, 1000),  # Adjust the size for better spacing
         xtickfontsize = fz, ytickfontsize = fz,
         fontfamily = "Courier New" , # Better Unicode support
         titlefontsize = fz+1,
         xguidefontsize = fz+1,
         yguidefontsize = fz+1,
         legendfontsize = fz-2,
         framestyle = :box,
         margin = 12mm,
         grid = :true,
         minorgrid = :true,
      

 )
hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.4)

plot!(buses_str, Y_D_ACOPF, color=RGB(237/255,201/255,81/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
 Y_D_Decoupled,
 label = "DECOUPLED_OPF",
 color = RGB(0/255,160/255,176/255),
 markersize = 11,
 alpha = 1,
 markerstrokewidth = 0,
 )
 plot!(buses_str, Y_D_Decoupled, color=RGB(0/255,160/255,176/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
         Y_D_LINEAR,
         label = "Linear_Thesis_OPF",
         color = RGB(204/255,42/255,54/255),
         markersize = 11,
         alpha = 1,
         markerstrokewidth = 0,
)
plot!(buses_str, Y_D_LINEAR, color=RGB(204/255,42/255,54/255), lw=2,label = false)  # Add line plot to connect points

# scatter!(buses_str,
#          Y_D_LINEAR_fixed,
#          label = "Linear_Thesis_OPF_with_fixed_active",
#          color = :green,
#          alpha = 0.8,
#          markersize = 11,
#          markerstrokewidth = 0.6,
# )
# plot!(buses_str, Y_D_LINEAR_fixed, color=:green, lw=2,label = false)  # Add line plot to connect points

# scatter!(buses_str,
#          Y_D_ACOPF_fixed,
#          label = "ACOPF_modified",
#          color = :purple,
#          markersize = 8,
#          markerstrokewidth = 0.86,
# )
# plot!(buses_str, Y_D_ACOPF_fixed, color=:purple, lw=2,label = false)  # Add line plot to connect points

scatter!(buses_str,
 Y_D_BTheta,
 label = "BTHETA_OPF",
 color = RGB(79/255,55/255,45/255),
 markersize = 11,
 markershape = :xcross,
 alpha = 1,
 markerstrokewidth = 0.8,
 )
 plot!(buses_str, Y_D_BTheta, color=RGB(79/255,55/255,45/255), lw=2,label = false)  # Add line plot to connect points

display(Delta)

# # Define output filepath
base_path = "/Users/malexandrakis/Documents/Diploma_Thesis/Plots"
output_dir = joinpath(base_path, base_name)
mkpath(output_dir)  # Creates all necessary parent directories

# # Define versioned filename
version = 100
#filename = base_name * "_Voltage_Angle_fixed_V$version.pdf"
filename = base_name * "_Voltage_Angle_V$version.pdf"
save_path = joinpath(output_dir, filename)

# # Save the plot 
savefig(Delta, save_path)