using Plots
using DataFrames
using LinearAlgebra,Dates,Statistics
using XLSX, Plots , PlotThemes,Printf,Interpolations


filename1 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","ACOPF_Paper_nodes_PV.xlsx")
filename2 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","ACOPF_Paper_nodes_PV_fixed.xlsx")
filename3 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","BTheta_Paper_nodes_PV.xlsx")
filename4 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","Decoupled_Paper_nodes_PV.xlsx")
filename5 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","LINEAR_OPF_Paper_nodes_PV.xlsx")
filename6 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\Paper_nodes_PV","LINEAR_OPF_Paper_nodes_PV_fixed_active.xlsx")

filename1 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","ACOPF_ehv1.xlsx")
filename2 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","ACOPF_ehv1_fixed.xlsx")
filename3 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","BTheta_ehv1.xlsx")
filename4 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","Decoupled_ehv1.xlsx")
filename5 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","LINEAR_OPF_ehv1.xlsx")
filename6 = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\ehv1","LINEAR_OPF_Paper_nodes_PV_fixed_ehv1")




VD_ACOPF_df = DataFrame(XLSX.readtable(filename1, "bus"))
VD_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2, "bus"))
VD_BTheta_df = DataFrame(XLSX.readtable(filename3, "results"))
VD_Decoupled_df = DataFrame(XLSX.readtable(filename4, "results"))
VD_LINEAR_df = DataFrame(XLSX.readtable(filename5, "results"))
VD_LINEAR_fixed_df = DataFrame(XLSX.readtable(filename6, "results"))


Y_D_ACOPF = VD_ACOPF_df[!, "va_degree"]
Y_D_ACOPF_fixed = VD_ACOPF_fixed_df[!, "va_degree"]
Y_D_BTheta = VD_BTheta_df[!, "Delta"]
Y_D_Decoupled = VD_Decoupled_df[!, "Delta"]
Y_D_LINEAR = VD_LINEAR_df[!, "va_degree"]
Y_D_LINEAR_fixed = VD_LINEAR_fixed_df[!,"va_degree"]


#For LINEAR BOLOGNANI OPF
error_delta_Linear = Y_D_ACOPF - Y_D_LINEAR
absolute_error_delta_Linear = abs.(error_delta_Linear)
max_absolute_error_delta_linear = maximum(absolute_error_delta_Linear)
mean_absolute_error_delta_linear = mean(absolute_error_delta_Linear)

#For DC_BTHETA OPF
error_delta_BTheta = Y_D_ACOPF - Y_D_BTheta
absolute_error_delta_BTheta = abs.(error_delta_BTheta)
max_absolute_error_delta_BTheta = maximum(absolute_error_delta_BTheta)
mean_absolute_error_delta_BTheta = mean(absolute_error_delta_BTheta)

#For DC_DECOUPLED OPF
error_delta_Decoupled = Y_D_ACOPF - Y_D_Decoupled
absolute_error_delta_Decoupled = abs.(error_delta_Decoupled)
max_absolute_error_delta_Decoupled = maximum(absolute_error_delta_Decoupled)
mean_absolute_error_delta_Decoupled = mean(absolute_error_delta_Decoupled)

Delta_error_df = DataFrame(
    Model = ["LINEAR","BTheta","Decoupled"],
    Average_Voltage_delta_error_linear = [mean_absolute_error_delta_linear,mean_absolute_error_delta_BTheta,
        mean_absolute_error_delta_Decoupled],
    Max_Voltage_delta_error_linear= [max_absolute_error_delta_linear,max_absolute_error_delta_BTheta,
        max_absolute_error_delta_Decoupled]
)

    


#VOLTAGE MAGNITUDE
Y_V_ACOPF = VD_ACOPF_df[!, "vm_pu"]
Y_V_ACOPF_fixed = VD_ACOPF_fixed_df[!, "vm_pu"]
Y_V_BTheta = VD_BTheta_df[!, "V_pu"]
Y_V_Decoupled = VD_Decoupled_df[!, "V_pu"]
Y_V_LINEAR = VD_LINEAR_df[!, "vm_pu"]
Y_V_LINEAR_fixed = VD_LINEAR_fixed_df[!,"vm_pu"]


#For LINEAR BOLOGNANI OPF
error_voltage_Linear = Y_V_ACOPF - Y_V_LINEAR
absolute_error_voltage_Linear = abs.(error_voltage_Linear)
max_absolute_error_voltage_linear =maximum(absolute_error_voltage_Linear)
mean_absolute_error_voltage_linear = mean(absolute_error_voltage_Linear)

#For DC_BTHETA OPF
error_voltage_BTheta = Y_V_ACOPF - Y_V_BTheta
absolute_error_voltage_BTheta = abs.(error_voltage_BTheta)
max_absolute_error_voltage_BTheta = maximum(absolute_error_voltage_BTheta)
mean_absolute_error_voltage_BTheta = mean(absolute_error_voltage_BTheta)

#For DC_DECOUPLED OPF
error_voltage_Decoupled = Y_V_ACOPF - Y_V_Decoupled
absolute_error_voltage_Decoupled = abs.(error_voltage_Decoupled)
max_absolute_error_voltage_Decoupled = maximum(absolute_error_voltage_Decoupled)
mean_absolute_error_voltage_Decoupled = mean(absolute_error_voltage_Decoupled)

Voltage_error_df = DataFrame(
    Model = ["LINEAR","BTheta","Decoupled"],
    Average_Absolute_Voltage_Magnitude_error = [mean_absolute_error_voltage_linear,mean_absolute_error_voltage_BTheta,
        mean_absolute_error_voltage_Decoupled],
    Max_Absolute_Voltage_Magnitude_error = [max_absolute_error_voltage_linear,max_absolute_error_voltage_BTheta,
        max_absolute_error_voltage_Decoupled]
)
#############################################################################
production_ACOPF_df = DataFrame(XLSX.readtable(filename1, "prod"))
production_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2, "prod"))
production_BTheta_df = DataFrame(XLSX.readtable(filename3, "production"))
production_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
production_LINEAR_df = DataFrame(XLSX.readtable(filename5, "production"))
production_LINEAR_fixed_active_df = DataFrame(XLSX.readtable(filename6, "production"))


Y_ACOPF = production_ACOPF_df[!, "p"]
Y_ACOPF_fixed = production_ACOPF_fixed_df[!, "p"]
Y_BTheta = production_BTheta_df[!, "production"]
Y_Decoupled = production_Decoupled_df[!, "production"]
Y_LINEAR = production_LINEAR_df[!, "production"]
Y_LINEAR_fixed = production_LINEAR_fixed_active_df[!, "production"]


#For LINEAR BOLOGNANI OPF
relative_error_production_Linear = abs.(100*(Y_LINEAR.-Y_ACOPF))./abs.(Y_ACOPF)
max_relative_error_production_linear = maximum(relative_error_production_Linear)
mean_relative_error_production_linear = mean(relative_error_production_Linear)

absolute_error_production_Linear = abs.(Y_LINEAR.-Y_ACOPF)
max_absolute_error_production_linear = maximum(absolute_error_production_Linear)
mean_absolute_error_production_linear = mean(absolute_error_production_Linear)

#For DC_BTHETA OPF
relative_error_production_BTheta = abs.(100*(Y_BTheta.-Y_ACOPF))./abs.(Y_ACOPF)
max_relative_error_production_BTheta = maximum(relative_error_production_BTheta)
mean_relative_error_production_BTheta = mean(relative_error_production_BTheta)

absolute_error_production_BTheta = abs.(Y_BTheta.-Y_ACOPF)
max_absolute_error_production_BTheta = maximum(absolute_error_production_BTheta)
mean_absolute_error_production_BTheta = mean(absolute_error_production_BTheta)

#For DC_DECOUPLED OPF
relative_error_production_Decoupled = abs.(100*(Y_Decoupled.-Y_ACOPF))./abs.(Y_ACOPF)
max_relative_error_production_Decoupled = maximum(relative_error_production_Decoupled)
mean_relative_error_production_Decoupled = mean(relative_error_production_Decoupled)

absolute_error_production_Decoupled = abs.(Y_Decoupled.-Y_ACOPF)
max_absolute_error_production_Decoupled = maximum(absolute_error_production_Decoupled)
mean_absolute_error_production_Decoupled = mean(absolute_error_production_Decoupled)

Production_error_df = DataFrame(
    Model = ["LINEAR","BTheta","Decoupled"],
    Average_Absolute_Production_error = [mean_absolute_error_production_linear,mean_absolute_error_production_BTheta,
        mean_absolute_error_production_Decoupled],
    Max_Absolute_Production_error = [max_absolute_error_production_linear,max_absolute_error_production_BTheta,
        max_absolute_error_production_Decoupled],
    Average_Relative_Production_error = [mean_relative_error_production_linear,mean_relative_error_production_BTheta,
        mean_relative_error_production_Decoupled],
    Max_Relative_Production_error = [max_relative_error_production_linear,max_relative_error_production_BTheta,
        max_relative_error_production_Decoupled]
)


##################################################################################
reactive_ACOPF_df = DataFrame(XLSX.readtable(filename1, "reactive"))
reactive_ACOPF_fixed_df = DataFrame(XLSX.readtable(filename2, "reactive"))
reactive_Decoupled_df = DataFrame(XLSX.readtable(filename4, "production"))
reactive_LINEAR_df = DataFrame(XLSX.readtable(filename5, "Reactive_Production"))
reactive_LINEAR_fixed_active_df = DataFrame(XLSX.readtable(filename6, "Reactive_Production"))

Y_reactive_ACOPF = reactive_ACOPF_df[!, "q_pu"]
Y_reactive_ACOPF_fixed = reactive_ACOPF_fixed_df[!, "q_pu"]
Y_reactive_Decoupled = reactive_Decoupled_df[!, "q"]
Y_reactive_LINEAR = reactive_LINEAR_df[!, "q_pu"]
Y_reactive_LINEAR_fixed = reactive_LINEAR_fixed_active_df[!, "q_pu"]

#For LINEAR BOLOGNANI OPF
relative_error_reactive_Linear = abs.(100*(Y_reactive_LINEAR.-Y_reactive_ACOPF))./abs.(Y_reactive_ACOPF)
max_relative_error_reactive_linear = maximum(relative_error_reactive_Linear)
mean_relative_error_reactive_linear = mean(relative_error_reactive_Linear)

absolute_error_reactive_Linear = abs.(Y_reactive_LINEAR.-Y_reactive_ACOPF)
max_absolute_error_reactive_linear = maximum(absolute_error_reactive_Linear)
mean_absolute_error_reactive_linear = mean(absolute_error_reactive_Linear)

#For DC_DECOUPLED OPF
relative_error_reactive_Decoupled = abs.(100*(Y_reactive_Decoupled.-Y_reactive_ACOPF))./abs.(Y_reactive_ACOPF)
max_relative_error_reactive_Decoupled = maximum(relative_error_reactive_Decoupled)
mean_relative_error_reactive_Decoupled = mean(relative_error_reactive_Decoupled)

absolute_error_reactive_Decoupled = abs.(Y_reactive_Decoupled.-Y_reactive_ACOPF)
max_absolute_error_reactive_Decoupled = maximum(absolute_error_reactive_Decoupled)
mean_absolute_error_reactive_Decoupled = mean(absolute_error_reactive_Decoupled)

Reactive_error_df = DataFrame(
    Model = ["LINEAR","Decoupled"],
    Average_Absolute_Reactive_error = [mean_absolute_error_reactive_linear,mean_absolute_error_reactive_Decoupled],
    Max_Absolute_Reactive_error = [max_absolute_error_reactive_linear,max_absolute_error_reactive_Decoupled],
    Average_Relative_Reactive_error = [mean_relative_error_reactive_linear,mean_relative_error_reactive_Decoupled],
    Max_Relative_Reactive_error = [max_relative_error_reactive_linear,max_relative_error_reactive_Decoupled]
)