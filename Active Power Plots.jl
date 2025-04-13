using Plots
using Plots.PlotMeasures
using StatsPlots
using DataFrames
using LinearAlgebra,Dates
using XLSX, Plots , PlotThemes,Printf





# Set the file paths and load data
#filepath1 = "/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Results/Paper_nodes_PV"
filepath1 = "/Users/malexandrakis/Documents/Results/Paper_nodes_PV"
filename1 = joinpath(filepath1,"ACOPF_Paper_nodes_PV.xlsx")
filename2 = joinpath(filepath1,"ACOPF_Paper_nodes_PV_fixed.xlsx")
filename3 = joinpath(filepath1,"BTheta_Paper_nodes_PV.xlsx")
filename4 = joinpath(filepath1,"Decoupled_Paper_nodes_PV.xlsx")
filename5 = joinpath(filepath1,"LINEAR_OPF_Paper_nodes_PV.xlsx")


filepath2 = "/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Results/ehv1"
filename1 = joinpath(filepath2,"ACOPF_ehv1.xlsx")
filename2 = joinpath(filepath2,"ACOPF_ehv1_fixed.xlsx")
filename3 = joinpath(filepath2,"BTheta_ehv1.xlsx")
filename4 = joinpath(filepath2,"Decoupled_ehv1.xlsx")
filename5 = joinpath(filepath2,"LINEAR_OPF_ehv1.xlsx")


filepath3 = "/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Results/ehv5"
filename1 = joinpath(filepath3,"ACOPF_ehv5.xlsx")
filename2 = joinpath(filepath3,"ACOPF_ehv5_fixed.xlsx")
filename3 = joinpath(filepath3,"BTheta_ehv5.xlsx")
filename4 = joinpath(filepath3,"Decoupled_ehv5.xlsx")
filename5 = joinpath(filepath3,"LINEAR_OPF_ehv5.xlsx")

filepath4 = "/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Results/ehv4"
filename1 = joinpath(filepath4,"ACOPF_ehv4.xlsx")
filename2 = joinpath(filepath4,"ACOPF_ehv4_fixed.xlsx")
filename3 = joinpath(filepath4,"BTheta_ehv4.xlsx")
filename4 = joinpath(filepath4,"Decoupled_ehv4.xlsx")
filename5 = joinpath(filepath4,"LINEAR_OPF_ehv4.xlsx")



##################################################################################
production_ACOPF_df = DataFrame(XLSX.readtable(filename1, "prod"))
production_BTheta_df = DataFrame(XLSX.readtable(filename3, "production"))
production_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
production_LINEAR_df = DataFrame(XLSX.readtable(filename5, "production"))
##################################################################################
VD_ACOPF_df = DataFrame(XLSX.readtable(filename1, "bus"))
VD_BTheta_df = DataFrame(XLSX.readtable(filename3, "results"))
VD_Decoupled_df = DataFrame(XLSX.readtable(filename4, "results"))
VD_LINEAR_df = DataFrame(XLSX.readtable(filename5, "results"))
##################################################################################
reactive_ACOPF_df = DataFrame(XLSX.readtable(filename1, "reactive"))
reactive_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
reactive_LINEAR_df = DataFrame(XLSX.readtable(filename5, "Reactive_Production"))
##################################################################################
prices_ACOPF_df = DataFrame(XLSX.readtable(filename1, "price"))
prices_BTheta_df = DataFrame(XLSX.readtable(filename3, "price"))
prices_Decoupled_df = DataFrame(XLSX.readtable(filename4, "price"))
prices_LINEAR_df = DataFrame(XLSX.readtable(filename5, "Price"))

X= production_ACOPF_df.bus



# #  https://www.color-hex.com/color-palette/894 <-- This is the colour palette that we will use as a basis


# ACTIVE POWER PRODUCTION Plotting
###########################################
###########################################
Y_ACOPF = production_ACOPF_df[!, "p"]
Y_BTheta = production_BTheta_df[!, "production"]
Y_Decoupled = production_Decoupled_df[!, "production"]
Y_LINEAR = production_LINEAR_df[!, "production"]

bus_count = length(X)
max_production = maximum([maximum(Y_ACOPF), maximum(Y_BTheta), maximum(Y_Decoupled),maximum(Y_LINEAR)])

# Data preparation
buses = production_ACOPF_df.bus

Y_ACOPF = production_ACOPF_df[!, "p"]



fz = 18 # fontsize <-- great for IEEE journal templates
zoom_out = 0.2
y_min = minimum([minimum(Y_ACOPF), minimum(Y_BTheta), minimum(Y_Decoupled),minimum(Y_LINEAR)])
y_max = maximum([maximum(Y_ACOPF), maximum(Y_BTheta), maximum(Y_Decoupled),maximum(Y_LINEAR)])
y_median = (y_min + y_max)/2
y_range = y_max - y_min
ylim = (max(y_median - (y_range + zoom_out)/2, 0), 
        y_median + (y_range + zoom_out)/2)
xlim = (0.5,bus_count+2.2)




bar_width = 0.2  # Width of each bar
offset = 0.2
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses


# Create a base bar chart for the first dataset
production = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_ACOPF,  # Values for the first dataset
    ylim = (max(y_median - (y_range + zoom_out)/2, 0), y_median + (y_range + zoom_out)/2),
    xlim = (0.5,bus_count+2.2),
    xlabel = "Buses",
    ylabel = "Active Power Production [p.u.]",
    #title = "Active Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(237/255,201/255,81/255),  # Color for the dataset
    bar_width = bar_width,  # Set the width of the bars
    size = (1000, 1000),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = 0:0.5:2,  
    xtickfontsize = fz, ytickfontsize = fz,
    fontfamily = "Courier New" , # Better Unicode support
    titlefontsize = fz,
    xguidefontsize = fz,
    yguidefontsize = fz,
    legendfontsize = fz-6,
    legend = :true,
    framestyle = :box,
    margin = 10mm,
    grid = :true,
    minorgrid = :true,
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(204/255,42/255,54/255),
    bar_width = bar_width,  # Set the width of the bars
)


bar!(x_indices .+ 0*offset,  # Center the first group of bars
    Y_BTheta,  # Values for the first dataset
    label = "BTHETA_OPF",
    color = RGB(79/255,55/255,45/255),
    bar_width = bar_width,  # Set the width of the bars
)

bar!(x_indices .+ 1*offset,  # Center the first group of bars
    Y_Decoupled,  # Values for the first dataset
    label = "Decoupled_OPF",
    color = RGB(0/255,160/255,176/255),
    bar_width = bar_width,  # Set the width of the bars

)

savefig("/Users/malexandrakis/Documents/Diploma_Thesis/Plots/paper_pv_active_V2.pdf")
#Voltage Magnitude Plotting
##############################################
##############################################
Y_V_ACOPF = VD_ACOPF_df[!, "vm_pu"]
Y_V_BTheta = VD_BTheta_df[!, "V_pu"]
Y_V_Decoupled = VD_Decoupled_df[!, "V_pu"]
Y_V_LINEAR = VD_LINEAR_df[!, "vm_pu"]

max_voltage = maximum([maximum(Y_V_ACOPF),  maximum(Y_V_BTheta), maximum(Y_V_Decoupled),maximum(Y_V_LINEAR)])
min_voltage = minimum([minimum(Y_V_ACOPF),  minimum(Y_V_BTheta), minimum(Y_V_Decoupled),minimum(Y_V_LINEAR)])
zoom_out = 0.01
# zoom_out = 1.0



y_min = min_voltage
y_max = max_voltage
y_median = (y_min + y_max)/2
y_range = y_max - y_min



ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2)

# Data preparation
buses = VD_ACOPF_df.Bus
bus_count = length(buses)
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_V = 0:1:bus_count+20
xticks_values_V = 0:5:56
xticks_labels_V = buses_str[1:5:end]


V = scatter(buses_str,
         Y_V_ACOPF,
         ylim = (y_median - (y_range+ zoom_out)/2, y_median + (y_range+ zoom_out)/2),
         xlim = (0,bus_count),
         xlabel = "Buses",
         ylabel = "Voltage Magnitude [p.u.]",
         #title = "Voltage Magnitude",
         legend = :bottomleft,
         label = "ACOPF",
         markersize = 11,
         color = RGB(237/255,201/255,81/255),  # Color for the dataset
         #alpha = 0.8,
        markerstrokewidth = 1,
         yticks = 0.96:0.02:1.5,
         xticks = (xticks_values_V,xticks_labels_V),  # Set xticks and labels
         xrotation = 0, # Rotate labels by 45 degrees
         markershape = :circle,
         size = (2000, 1000),  # Adjust the size for better spacing
         xtickfontsize = fz, ytickfontsize = fz,
         fontfamily = "Courier New" , # Better Unicode support
         titlefontsize = fz+1,
         xguidefontsize = fz+1,
         yguidefontsize = fz+1,
         legendfontsize = fz-2,
         framestyle = :box,
         margin = 10mm,
         grid = :true,
         minorgrid = :true,
      

 )


 plot!(buses_str, Y_V_ACOPF, color=RGB(237/255,201/255,81/255), lw=2,label = false)  # Add line plot to connect points

 hline!([0.8], linestyle = :dash, color = :black, label = "",)
 hline!([1.2], linestyle = :dash, color = :black, label = "",)


 scatter!(buses_str,
         Y_V_BTheta,
         label = "BTHETA_OPF",
         color = RGB(79/255,55/255,45/255),
         markerstrokewidth = 1,
         markersize = 11,
         #alpha = 0.6,
         markershape = :xcross

)
plot!(buses_str, Y_V_BTheta, color= RGB(79/255,55/255,45/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
Y_V_Decoupled,
label = "DECOUPLED_OPF",
color = RGB(0/255,160/255,176/255),
markersize = 11,
markerstrokewidth = 1,
#alpha = 0.9,
#markershape = :xcross
)
plot!(buses_str, Y_V_Decoupled, color= RGB(0/255,160/255,176/255), lw=2,label = false)  # Add line plot to connect points



scatter!(buses_str,
         Y_V_LINEAR,
         label = "Linear_Thesis_OPF",
         color = RGB(204/255,42/255,54/255),
         markersize = 11,
         markerstrokewidth = 1,
         #alpha = 0.7,
         #markershape = :hex
)
plot!(buses_str, Y_V_LINEAR, color= RGB(204/255,42/255,54/255), lw=2,label = false)  # Add line plot to connect points


savefig("/Users/malexandrakis/Documents/Diploma_Thesis/Plots/paper_Voltage_Magnitude_V4.pdf")


#Voltage Angle Plotting
##############################################
##############################################
Y_D_ACOPF = VD_ACOPF_df[!, "va_degree"]
Y_D_BTheta = VD_BTheta_df[!, "Delta"]
Y_D_Decoupled = VD_Decoupled_df[!, "Delta"]
Y_D_LINEAR = VD_LINEAR_df[!, "va_degree"]


max_delta = maximum([maximum(Y_D_ACOPF), maximum(Y_D_BTheta), maximum(Y_D_Decoupled), maximum(Y_D_LINEAR)])
min_delta = minimum([minimum(Y_D_ACOPF), minimum(Y_D_BTheta), minimum(Y_D_Decoupled), minimum(Y_D_LINEAR)])


zoom_out = 0.3
# zoom_out = 1.0
ylim = (y_median - abs((y_range+ zoom_out)/2), y_median + abs((y_range+ zoom_out)/2))



y_min = min_delta
y_max = max_delta
y_median = (y_min + y_max)/2
y_range = y_max - y_min



ylim = (y_median - abs((y_range+ zoom_out)/2), y_median + abs((y_range+ zoom_out)/2))

# Data preparation
buses = VD_ACOPF_df.Bus
bus_count = length(buses)
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_V = 0:1:bus_count+20
xticks_values_D = 0:5:56
xticks_labels_D = buses_str[1:5:end]






# Data preparation
buses = VD_ACOPF_df.Bus
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)




Delta = scatter(buses_str,
         Y_D_ACOPF,
         ylim = (y_median - abs((y_range+ zoom_out)/2), y_median + abs((y_range+ zoom_out)/2)),
         xlim = (0,bus_count),
         xlabel = "Buses",
         ylabel = "Delta[°]",
         #title = "Voltage Angle",
         legend = :bottomleft,
         label = "ACOPF",
         markersize = 11,
         color = RGB(237/255,201/255,81/255),  # Color for the dataset
         #alpha = 0.8,
        markerstrokewidth = 1,
         yticks = -2:0.2:0.6,
         xticks = (xticks_values_D,xticks_labels_D),  # Set xticks and labels
         xrotation = 0, # Rotate labels by 45 degrees
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
         Y_D_BTheta,
         label = "BTHETA_OPF",
         color = RGB(79/255,55/255,45/255),
         markersize = 12,
        markershape = :xcross
)
plot!(buses_str, Y_D_BTheta, color=RGB(79/255,55/255,45/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
Y_D_Decoupled,
label = "DECOUPLED_OPF",
color = RGB(0/255,160/255,176/255),
markersize = 11,
)
plot!(buses_str, Y_D_Decoupled, color=RGB(0/255,160/255,176/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
         Y_D_LINEAR,
         label = "Linear_Thesis_OPF",
         color = RGB(204/255,42/255,54/255),
         markersize = 11,
)
plot!(buses_str, Y_D_LINEAR, color=RGB(204/255,42/255,54/255), lw=2,label = false)  # Add line plot to connect points

savefig("/Users/malexandrakis/Documents/Diploma_Thesis/Plots/paper_Voltage_Angle_V2.pdf")

#Reactive Production Plotting
##############################################
##############################################
Y_reactive_ACOPF = reactive_ACOPF_df[!, "q_pu"]
Y_reactive_Decoupled = reactive_Decoupled_df[!, "q"]
Y_reactive_LINEAR = reactive_LINEAR_df[!, "q_pu"]

buses = production_ACOPF_df.bus
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)


max_reactive = maximum([maximum(Y_reactive_ACOPF),  maximum(Y_reactive_Decoupled), maximum(Y_reactive_LINEAR)])
min_reactive = minimum([minimum(Y_reactive_ACOPF),  minimum(Y_reactive_Decoupled), minimum(Y_reactive_LINEAR)])





fz = 18 # fontsize <-- great for IEEE journal templates
zoom_out = -1.3
y_min = max_reactive
y_max = min_reactive
y_median = (y_min + y_max)/2
y_range = y_max - y_min
ylim = (y_median - abs((y_range + zoom_out)/2), 
        y_median + abs((y_range + zoom_out)/2))
xlim = (0.5,bus_count+2.2)




bar_width = 0.2  # Width of each bar
offset = 0.2
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses


bus_count = length(X)
buses_str


y_format(y) = y < 0 ? string('\u2212', abs(y)) : string(y)  # U+2212 = proper minus

# Create a base bar chart for the first dataset
reactive = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_reactive_ACOPF,  # Values for the first dataset
    ylim = (y_median - abs((y_range + zoom_out)/2), 
        y_median + abs((y_range + zoom_out)/2)),
    xlim = (0.5,bus_count+1.6),
    xlabel = "Buses",
    ylabel = "Reactive Power Production [p.u.]",
    #title = "Reactive Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(237/255,201/255,81/255),  # Color for the dataset
    legend = :topright,
    bar_width = bar_width,  # Set the width of the bars
    size = (1000, 1000),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = -2:0.5:2.5,  
    xtickfontsize = fz, ytickfontsize = fz,
    fontfamily = "Courier New" , # Better Unicode support
    titlefontsize = fz,
    xguidefontsize = fz,
    yguidefontsize = fz,
    legendfontsize = fz-6,
    framestyle = :box,
    margin = 10mm,
    grid = :true,
    minorgrid = :true,
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_reactive_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(204/255,42/255,54/255),
    bar_width = bar_width,  # Set the width of the bars

)


bar!(x_indices .+ 0*offset,  # Center the first group of bars
    Y_reactive_Decoupled,  # Values for the first dataset
    label = "Decoupled_OPF",
    color = RGB(0/255,160/255,176/255),
    bar_width = bar_width,  # Set the width of the bars


)

hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.5)



savefig("/Users/malexandrakis/Documents/Diploma_Thesis/Plots/paper_pv_reactive_V2.pdf")



#Price Plotting
###############################################################################
###############################################################################
Y_prices_ACOPF = prices_ACOPF_df[!, "node_price"]
Y_prices_BTheta = prices_BTheta_df[!, "node_price"]
Y_prices_Decoupled = prices_Decoupled_df[!, "node_price"]
Y_prices_LINEAR = prices_LINEAR_df[!, "price"]


max_price = maximum([maximum(Y_prices_ACOPF),  maximum(Y_prices_BTheta), maximum(Y_prices_Decoupled), maximum(Y_prices_LINEAR)])
 min_price = minimum([minimum(abs.(Y_prices_ACOPF)),  minimum(abs.(Y_prices_BTheta)), minimum(abs.(Y_prices_Decoupled)), minimum(abs.(Y_prices_LINEAR))])
#min_price = 0

buses = VD_ACOPF_df.Bus
bus_count = length(buses)
step = 10
lower = 1130
upper = 1170

length1 = trunc(Int,-((lower-upper)/(step) - 1))
length1
y_ticks_values_prices = vcat(1150, collect(range(lower, stop = upper, length = length1)))
y_ticks_labels_prices = [@sprintf("%.2f", v) for v in y_ticks_values_prices]

buses_str = string.(buses)
xticks_values_prices = 0:1:bus_count+20
xticks_labels_prices = buses_str[1:1:end]

theme(:wong2)

prices = scatter(buses_str,
            Y_prices_ACOPF,
            ylim = (lower,upper),
            xlim = (0,bus_count),
            xlabel = "Buses",
            ylabel = "Price[pu]",
            title = "Price",
            legend = :topleft,
            label = "ACOPF",
            markersize = 10,
            color = RGB(142/255,193/255,39/255),
            alpha = 0.6,
            yticks = (y_ticks_values_prices, y_ticks_labels_prices),
            xticks = (xticks_values_prices,xticks_labels_prices),  # Set xticks and labels
            size = (1600, 800),
            legendfontsize = 12, # Reduce legend font size
            xrotation = 70 # Rotate labels by 45 degrees
    )
    
hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.4)
    
plot!(buses_str, Y_prices_ACOPF, color=RGB(142/255,193/255,39/255), lw=2,label = false)  # Add line plot to connect points


scatter!(
    buses_str,
    Y_prices_BTheta,
    label = "BTHETA_OPF",
    color = RGB(162/255,0/255,255/255),
    markersize = 9,
    alpha = 0.6,
    markershape = :utriangle
)
#plot!(buses_str, Y_prices_BTheta, color=RGB(162/255,0/255,255/255), lw=2,label = false)  # Add line plot to connect points

scatter!(
    buses_str,
    Y_prices_Decoupled,
    label = "DECOUPLED_OPF",
    color = RGB(0/255,174/255,219/255),
    markersize = 9,
    alpha = 0.6,
    markershape = :xcross
)



#plot!(buses_str, Y_prices_Decoupled, color=RGB(0/255,174/255,219/255), lw=2,label = false)  # Add line plot to connect points
scatter!(
    buses_str,
    Y_prices_LINEAR,
    label = "Linear_Thesis_OPF",
    color = RGB(244/255,120/255,53/255),
    markersize = 14,
    alpha = 1.2,
    markershape = :+
)


hline!([1150], linestyle = :dash, color = :black, label = "",alpha = 0.5)
#hline!([30], linestyle = :dash, color = :black, label = "",alpha = 0.5)



#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\ehv4_priced.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/ehv5_priced.pdf")


# Titles for each subplot
titles = ["Plot 1", "Plot 2", "Plot 3", "Plot 4"]

# Create the layout for 4 subplots (2 rows, 2 columns)
layout = @layout [production reactive; V Delta]
layout2 = @layout[V;Delta]
ylabels = ["Active Power[pu]", "Reactive Power[pu]", "Voltage[pu]", "Delta[degrees]"]


V_no_label = scatter(V, ylabel = "",xlabel = "")
Delta_no_label = scatter(Delta, ylabel = "",xlabel = "")

production_no_label = scatter(production, ylabel = "",xlabel = "")
reactive_no_label = scatter(reactive, ylabel = "",xlabel = "")

# Combine the modified plots
plot(
    V_no_label,
    Delta_no_label,
    layout = layout2,
    size = (1800, 1200)
)
#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\paper_V_delta_plots.pdf")

plot(
    production_no_label,
    reactive_no_label,
    layout = layout2,
    size = (900, 700)
)
#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\paper_active_reactive_plots.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/paper_active_reactive_plots.pdf")

