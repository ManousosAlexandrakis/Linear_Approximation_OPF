using Plots
using DataFrames
using LinearAlgebra,Dates
using XLSX, Plots , PlotThemes,Printf





filepath1 = "/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Results/Paper_nodes_PV"
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
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
# Define the step size for the y-axis
lower = 0
upper = 2.2

step = 0.2

length1 = trunc(Int,-((lower-upper)/(step) - 1))
#yticks_values_production = range(-0.1, stop = max_production*1.1, length = 10)
yticks_values_production = vcat(0, collect(range(lower, stop = upper, length = length1)))
#yticks_values_production = -0.1:0.1:(max_production + 10)
yticks_labels_production = [@sprintf("%.2f", v) for v in yticks_values_production]

bar_width = 0.2  # Width of each bar
offset = 0.2
x_indices = 1:(length(buses_str)+2)/length(buses_str):length(buses_str)+2  # Numerical indices for the buses

theme(:wong2)
# Create a base bar chart for the first dataset
production = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_ACOPF,  # Values for the first dataset
    ylim = (lower,upper),
    xlim = (0.5,bus_count+2.2),
    xlabel = "Buses",
    ylabel = "Active Power Production [pu]",
    title = "Active Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(142/255,193/255,39/255),  # Color for the dataset
    legendfontsize = 12,
    bar_width = bar_width,  # Set the width of the bars
    size = (775, 500),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = (yticks_values_production, yticks_labels_production),  # Custom y-axis ticks and labels
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(244/255,120/255,53/255),
    bar_width = bar_width,  # Set the width of the bars

    yticks = (yticks_values_production, yticks_labels_production),  # Custom y-axis ticks and labels
)


bar!(x_indices .+ 0*offset,  # Center the first group of bars
    Y_BTheta,  # Values for the first dataset
    label = "BTHETA_OPF",
    color = RGB(162/255,0/255,255/255),
    bar_width = bar_width,  # Set the width of the bars
    yticks = (yticks_values_production, yticks_labels_production),  # Custom y-axis ticks and labels

)

bar!(x_indices .+ 1*offset,  # Center the first group of bars
    Y_Decoupled,  # Values for the first dataset
    label = "Decoupled_OPF",
    color = RGB(0/255,174/255,219/255),
    bar_width = bar_width,  # Set the width of the bars
    yticks = (yticks_values_production, yticks_labels_production),  # Custom y-axis ticks and labels

)

#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\ehv4_active.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/ehv4_active.pdf")
#Voltage Magnitude Plotting
##############################################
##############################################
Y_V_ACOPF = VD_ACOPF_df[!, "vm_pu"]
Y_V_BTheta = VD_BTheta_df[!, "V_pu"]
Y_V_Decoupled = VD_Decoupled_df[!, "V_pu"]
Y_V_LINEAR = VD_LINEAR_df[!, "vm_pu"]

max_voltage = maximum([maximum(Y_V_ACOPF),  maximum(Y_V_BTheta), maximum(Y_V_Decoupled),maximum(Y_V_LINEAR)])
min_voltage = minimum([minimum(Y_V_ACOPF),  minimum(Y_V_BTheta), minimum(Y_V_Decoupled),minimum(Y_V_LINEAR)])

lower = 0.96
upper = 1.02
yticks_values_V = range(lower, stop = upper, length = 7)


yticks_labels_V = [@sprintf("%.2f", v) for v in yticks_values_V]


# Data preparation
buses = VD_ACOPF_df.Bus
bus_count = length(buses)
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)
xticks_values_V = 0:1:bus_count+20
xticks_labels_V = buses_str[1:1:end]

theme(:wong2)
V = scatter(buses_str,
         Y_V_ACOPF,
         ylim = (lower,upper),
         xlim = (-0,bus_count),
         xlabel = "Buses",
         ylabel = "Voltage Magnitude[pu]",
         title = "Voltage Magnitude",
         legend = :bottomleft,
         label = "ACOPF",
         markersize = 10,
         color = RGB(142/255,193/255,39/255),
         alpha = 0.8,
         yticks = (yticks_values_V, yticks_labels_V),  # Set yticks and labels
         xticks = (xticks_values_V,xticks_labels_V),  # Set xticks and labels
         size = (1600, 800),
         legendfontsize = 13, 
         xrotation = 70, # Rotate labels by 45 degrees
         markershape = :circle,

 )


 plot!(buses_str, Y_V_ACOPF, color=RGB(142/255,193/255,39/255), lw=2,label = false)  # Add line plot to connect points

 hline!([0.8], linestyle = :dash, color = :black, label = "",)
 hline!([1.2], linestyle = :dash, color = :black, label = "",)


 scatter!(buses_str,
         Y_V_BTheta,
         label = "BTHETA_OPF",
         color = RGB(162/255,0/255,255/255),
         markersize = 9,
         alpha = 0.6,
         markershape = :utriangle

)
plot!(buses_str, Y_V_BTheta, color= RGB(162/255,0/255,255/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
Y_V_Decoupled,
label = "DECOUPLED_OPF",
color = RGB(0/255,174/255,219/255),
markersize = 9,
alpha = 0.9,
markershape = :xcross
)
plot!(buses_str, Y_V_Decoupled, color= RGB(0/255,174/255,219/255), lw=2,label = false)  # Add line plot to connect points



scatter!(buses_str,
         Y_V_LINEAR,
         label = "Linear_Thesis_OPF",
         color = RGB(244/255,120/255,53/255),
         markersize = 11,
         alpha = 0.7,
         markershape = :hex
)
plot!(buses_str, Y_V_LINEAR, color= RGB(244/255,120/255,53/255), lw=2,label = false)  # Add line plot to connect points


#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\ehv4_Voltage_Magnitude.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/paper_Voltage_Magnitude.pdf")

#Voltage Angle Plotting
##############################################
##############################################
Y_D_ACOPF = VD_ACOPF_df[!, "va_degree"]
Y_D_BTheta = VD_BTheta_df[!, "Delta"]
Y_D_Decoupled = VD_Decoupled_df[!, "Delta"]
Y_D_LINEAR = VD_LINEAR_df[!, "va_degree"]


max_delta = maximum([maximum(Y_D_ACOPF), maximum(Y_D_BTheta), maximum(Y_D_Decoupled), maximum(Y_D_LINEAR)])
min_delta = minimum([minimum(Y_D_ACOPF), minimum(Y_D_BTheta), minimum(Y_D_Decoupled), minimum(Y_D_LINEAR)])


if min_delta < 0.0000001 && min_delta > -0.0000001
    min_delta = -0.5
end

if max_delta < 0.0000001 && max_delta > -0.0000001
    max_delta = 0.4
end

#yticks_values_D = min_delta*1.1:((max_delta-min_delta)/8):max_delta*1.1
#yticks_values_D = range(min_delta * 1.1, stop = max_delta*1.1, length = 10)
lower = -2
upper = 0.2
yticks_values_D = vcat(0, collect(range(lower, stop = upper, length = 12)))

yticks_labels_D = [@sprintf("%.2f", v) for v in yticks_values_D]
bus_count = length(buses)

buses_str = string.(buses)
xticks_values_D = 0:1:bus_count+20
xticks_labels_D= buses_str[1:1:end]

# Data preparation
buses = VD_ACOPF_df.Bus
# Convert buses to a string to treat them as categorical
buses_str = string.(buses)

theme(:wong2)
Delta = scatter(buses_str,
         Y_D_ACOPF,
         ylim = (lower,upper),
         xlim = (0,bus_count),
         xlabel = "Buses",
         ylabel = "Delta[degrees]",
         title = "Voltage Angle",
         legend = :bottomleft,
         label = "ACOPF",
         markersize = 10,
         color = RGB(142/255,193/255,39/255),
         alpha = 0.6,
         yticks = (yticks_values_D, yticks_labels_D) ,
         xticks = (xticks_values_D,xticks_labels_D),  # Set yticks and labels
         #size = (700, 450),
         size = (1600, 800),
         legendfontsize = 13, # Reduce legend font size
         xrotation = 70 # Rotate labels by 45 degrees

         # markershape = [:circle :utriangle :diamond],)
 )
 hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.4)

 plot!(buses_str, Y_D_ACOPF, color=RGB(142/255,193/255,39/255), lw=2,label = false)  # Add line plot to connect points


 scatter!(buses_str,
         Y_D_BTheta,
         label = "BTHETA_OPF",
         color = RGB(162/255,0/255,255/255),
         markersize = 11,
         alpha = 0.7,
        markershape = :utriangle
)
plot!(buses_str, Y_D_BTheta, color=RGB(162/255,0/255,255/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
Y_D_Decoupled,
label = "DECOUPLED_OPF",
color = RGB(0/255,174/255,219/255),
markersize = 12,
alpha = 0.8,
markershape = :xcross
)
plot!(buses_str, Y_D_Decoupled, color=RGB(0/255,174/255,219/255), lw=2,label = false)  # Add line plot to connect points


scatter!(buses_str,
         Y_D_LINEAR,
         label = "Linear_Thesis_OPF",
         color = RGB(244/255,120/255,53/255),
         markersize = 10,
         alpha = 0.8,
         markershape = :hex
)
plot!(buses_str, Y_D_LINEAR, color=RGB(244/255,120/255,53/255), lw=2,label = false)  # Add line plot to connect points

#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\ehv4_Voltage_Angle.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/paper_Voltage_Angle.pdf")


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


# yticks_values_q = range(min_reactive * 1.1, stop = max_reactive*1.1, length = 10)
# yticks_labels_q = [@sprintf("%.2f", v) for v in yticks_values_q]
lower =-2.5
upper =2.5
yticks_values_q = vcat(0, collect(range(lower, stop = upper, length = 11)))

yticks_labels_q = [@sprintf("%.2f", v) for v in yticks_values_q]





bus_count = length(X)
buses_str

bar_width = 0.2  # Width of each bar
offset = 0.2
x_indices = 1:(length(buses_str)+1)/length(buses_str):length(buses_str)+1  # Numerical indices for the buses


theme(:wong2)
# Create a base bar chart for the first dataset
reactive = bar(
    x_indices .- 2offset,  # Center the first group of bars
    Y_reactive_ACOPF,  # Values for the first dataset
    ylim = (lower,upper),
    xlim = (0.5,bus_count+1.2),
    xlabel = "Buses",
    ylabel = "Reactive Power Production [pu]",
    title = "Reactive Power Production",
    label = "ACOPF",  # Label for the legend
    color = RGB(142/255,193/255,39/255),  # Color for the dataset
    legend = :bottomleft,
    legendfontsize = 10,
    bar_width = bar_width,  # Set the width of the bars
    size = (775, 500),  # Adjust the size for better spacing
    xticks = (x_indices, buses_str),  # Map numerical x-values to string labels
    yticks = (yticks_values_q, yticks_labels_q),  # Custom y-axis ticks and labels
)

bar!(
    x_indices .- 1*offset,  # Center the first group of bars
    Y_reactive_LINEAR,  # Values for the first dataset
    label = "Linear_Thesis_OPF",
    color = RGB(244/255,120/255,53/255),
    bar_width = bar_width,  # Set the width of the bars
    yticks = (yticks_values_q, yticks_labels_q),  # Custom y-axis ticks and labels
)


bar!(x_indices .+ 0*offset,  # Center the first group of bars
    Y_reactive_Decoupled,  # Values for the first dataset
    label = "Decoupled_OPF",
    color = RGB(0/255,174/255,219/255),
    bar_width = bar_width,  # Set the width of the bars
    yticks = (yticks_values_q, yticks_labels_q),  # Custom y-axis ticks and labels

)

hline!([0], linestyle = :dash, color = :black, label = "",alpha = 0.5)




#savefig("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Plots\\ehv4_reactive.pdf")
savefig("/Users/giorgosalexandrakes/Documents/Διπλωματική_Μανούσος/Διπλωματική/Διπλωματική Κώδικας/Thesis_Writing/Plots/paper_reactive.pdf")


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

