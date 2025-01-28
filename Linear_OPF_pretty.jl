using DataFrames, JuMP, GLPK ,Gurobi
using LinearAlgebra
using XLSX, Plots , PlotThemes

#a
model = Model(Gurobi.Optimizer)

filename = "Paper_nodes_PV.xlsx"
#filename = "2nodes-test_new.xlsx"
#filename = "2_nodes_file_arxiko_ruan.xlsx"
#filename = "3nodes-test.xlsx"
#filename = "Xanthi_opf.xlsx"
#filename = "Xanthi_opf_changed_V2.xlsx"
#filename = "Xanthi_opf_different_zbase.xlsx"
#filename = "Xanthi_opf_only_PQ.xlsx"  
#filename = "promised_ehv4_Ruan_for_my_code.xlsx"
#filename = "promised_HV_OH-UGa_Ruan_for_my_code.xlsx"
#filename = "promised_ehv4_Ruan_for_my_code.xlsx"
#filename = "promised_ehv6_Ruan_for_my_code.xlsx"
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","promised_ehv6_Ruan_for_my_code.xlsx")



#filename = "promised_HV-UG_Ruan_for_my_code.xlsx"      #αυτό έχει PV και δεν τρέχει
#filename = "promised_HV-UG-OHa_Ruan_for_my_code.xlsx"
#filename = "promised_HV-UG-OHb_Ruan_for_my_code.xlsx"

#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","2nodes-test_new.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","2nodes-test_newV15.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","2nodes-test_newV16.xlsx")


#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","3nodes-test_newV20.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","3nodes-test_newV21.xlsx")



#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","Paper_nodes_PV_simple_V4.xlsx")


#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","Paper_nodes_PV_changed_V2.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","Xanthi_opf_changed_V3.xlsx")
#filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Simple Datasets","3nodes-test_newV21.xlsx")
#filename ="promised_ehv1_Ruan_for_my_code.xlsx"


gen_data = DataFrame(XLSX.readtable(filename, "gen"))
Edges = DataFrame(XLSX.readtable(filename, "edges"))
bus_data = DataFrame(XLSX.readtable(filename, "bus"))
load_data = DataFrame(XLSX.readtable(filename, "load"))
slack_data = DataFrame(XLSX.readtable(filename, "ext_grid"))
Upward_data = DataFrame(XLSX.readtable(filename, "Upward"))
Downward_data = DataFrame(XLSX.readtable(filename, "Downward"))




Ssystem = 1
# Create a DataFrame for Edges
data = DataFrame(
    from_bus = Edges.from_bus,
    to_bus = Edges.to_bus,
    R = Edges.R_pu,
    X = Edges.X_pu,
    FlowMax = Edges.FlowMax
) 


# Create a dictionary to store max Flow
Flowmax = Dict{Tuple{Int, Int}, Float64}()

for row in eachrow(data)
    From = row.from_bus
    To = row.to_bus
    FlowMax = row.FlowMax
    
     # Store FlowMax for both directions in the dictionary using tuples as keys
     forward_edge = (From, To)
     backward_edge = (To, From)

     Flowmax[forward_edge] = FlowMax
     Flowmax[backward_edge] = FlowMax
end

Flowmax_edge_dict = Dict{Int, Float64}()
# Create a dictionary mapping idx to FlowMax
Flowmax_edge_dict = Dict{Int, Float64}()
for row in eachrow(Edges)
    Flowmax_edge_dict[row.idx] = row.FlowMax
end



slack_v = slack_data[1, :vm_pu]  #παίρνει απο το dataframe slack_data την πρωτη γραμμή της στήλης vm_pu
slack_degree = slack_data[1,:va_degree]
slack_bus = slack_data[1,:bus]

buses = bus_data[:, :bus]
edges_index = Edges[:,:idx]

slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
bus_id_to_index[slack_bus] = size(bus_data, 1)
bus_id_to_index_with_slack = Dict(bus_data[:, :bus] .=> 1:size(bus_data, 1))

# Create a dictionary to store connected buses
connected_buses_dict = Dict{Int, Vector{Int}}()
bus_id_to_index_with_slack
for row in eachrow(data)
    From = row.from_bus
    To = row.to_bus
    
    # Store connected buses in the dictionary
    if !haskey(connected_buses_dict, From)
        connected_buses_dict[From] = Int[]
    end
    push!(connected_buses_dict[From], To)
    
    # Bidirectional connection
    if !haskey(connected_buses_dict, To)
        connected_buses_dict[To] = Int[]
    end
    push!(connected_buses_dict[To], From)
end

#connected_buses_dict


# Total number of buses
n = size(bus_data,1)

n_edges = length(Edges.from_bus)
Lines = 1:n_edges


# Create an array to store all the Nodes
Nodes = Int[]
for row in eachrow(bus_data)
    bus = row.bus
    push!(Nodes, bus)
end
Nodes


# Create an array to store all the PV buses
PV_buses = Int[]
for row in eachrow(gen_data)
    bus_id = row.bus
    if bus_id !=slack_bus && !(bus_id in PV_buses)
        push!(PV_buses, bus_id)
    end
end
PV_buses
n_PV_buses = length(PV_buses)

# Create an array to store all the PQ buses
PQ_buses = filter(bus -> !(bus in PV_buses) && bus != slack_bus, Nodes)
n_PQ_buses = length(PQ_buses)

# Create an array to store all the PV buses along with the slack bus
slack_PV_buses = Int[]
for row in eachrow(gen_data)
    bus_id = row.bus
    if !(bus_id in slack_PV_buses)
        push!(slack_PV_buses, bus_id)
    end
end
slack_PV_buses
n_slack_PV_buses = length(slack_PV_buses)

# Create an array to store all the PV and PQ buses
PV_PQ_buses = setdiff(Nodes, [slack_bus])
n_PV_PQ_buses = length(PV_PQ_buses)


################################# Mapping of bus names to indexes ##############################
slack_index = findfirst(bus_data[:, :bus] .== slack_bus)


# slack bus has the largest idx
slack_map = Dict{Int,Int}()
slack_map[slack_bus] = size(bus_data, 1)

# Create a map for all the PV buses
PV_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(PV_buses))

# Create a map for all the PQ buses
PQ_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(PQ_buses))

# Combine all mappings into a single comprehensive mapping
complete_mapping = Dict{Any, Int}()

# Add all entries from PV_bus_mapping to complete_mapping
for (bus_id, index) in PV_bus_mapping
    complete_mapping[bus_id] = index
end


# Add all entries from PQ_bus_mapping to complete_mapping
for (bus_id, index) in PQ_bus_mapping
    complete_mapping[bus_id] = index + length(PV_buses)
end

# Add the slack bus entry to complete_mapping
complete_mapping[slack_bus] = size(bus_data, 1)
complete_mapping


# Create the Admittance Matrix
# Create the Admittance Matrix
# Add the slack bus entry to complete_mapping
complete_mapping[slack_bus] = size(bus_data, 1)


global Y = zeros(Complex, n, n)
global Z_w_slack = zeros(Complex, n, n)
for row in eachrow(data)
    From_Bus = complete_mapping[row.from_bus]
    To_Bus = complete_mapping[row.to_bus]
    x = row.X
    r = row.R
    local z = r + x .* im
    local y_admit = 1 ./ z[1]
    Y[From_Bus, To_Bus] = -y_admit
    Y[To_Bus, From_Bus] = -y_admit
    Y[From_Bus, From_Bus] = Y[From_Bus, From_Bus] +  y_admit
    Y[To_Bus, To_Bus] = Y[To_Bus, To_Bus] +  y_admit
    Z_w_slack[From_Bus, To_Bus] = -1 ./y_admit
    Z_w_slack[To_Bus, From_Bus] = -1 ./y_admit
    Z_w_slack[From_Bus, From_Bus] = Z_w_slack[From_Bus, From_Bus] +  1 ./y_admit
    Z_w_slack[To_Bus, To_Bus] = Z_w_slack[To_Bus, To_Bus] +  1 ./y_admit
end

# # Create the Admittance Matrix excluding the row that refers to the slack bus
sl = slack_map[slack_bus]
Y_without_slack =Y[ 1:end .!= sl, 1:end .!= sl]
Y
# # Create the Impedance Matrix excluding the slack bus
# Z = zeros(Complex, n_PV_PQ_buses, n_PV_PQ_buses)
Z = inv(Y_without_slack)
df_Z = DataFrame(Z, :auto)
# sl = slack_map[slack_bus]
# Z = Z_w_slack[ 1:end .!= sl, 1:end .!= sl]
#show(stdout, "text/plain", df_Z)





# Create the R and X Matrices excluding the slack bus
global R_matrix = zeros(Float64, n_PV_PQ_buses, n_PV_PQ_buses)
global X_matrix = zeros(Float64, n_PV_PQ_buses, n_PV_PQ_buses)

R_matrix = real.(Z)
X_matrix = imag.(Z)
df_R = DataFrame(R_matrix, :auto)
df_X = DataFrame(X_matrix, :auto)
#XLSX.writetable("Z Matrix for Paper.xlsx", "R matrix"=> df_R , "X matrix"=> df_X )

########################################################################
########################################################################
########################################################################
########################################################################
# Create Matrices that are used on the paper
global R_VV = zeros(Float64, n_PV_buses, n_PV_buses)
global X_VV = zeros(Float64, n_PV_buses, n_PV_buses)
global R_VQ = zeros(Float64, n_PV_buses, n_PQ_buses)
global X_VQ = zeros(Float64, n_PV_buses, n_PQ_buses)

global R_QV = zeros(Float64, n_PQ_buses, n_PV_buses)
global X_QV = zeros(Float64, n_PQ_buses, n_PV_buses)
global R_QQ = zeros(Float64, n_PQ_buses, n_PQ_buses)
global X_QQ = zeros(Float64, n_PQ_buses, n_PQ_buses)


#R_VV and X_VV
for k in PV_buses
    for m in PV_buses
        R_VV[PV_bus_mapping[k], PV_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_VV[PV_bus_mapping[k], PV_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
    end
end



#R_VQ and X_VQ
for k in PV_buses
    for m in PQ_buses
            R_VQ[PV_bus_mapping[k], PQ_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_VQ[PV_bus_mapping[k], PQ_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
    end 
end



#R_QV and X_QV
for k in PQ_buses
    for m in PV_buses
        R_QV[PQ_bus_mapping[k], PV_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_QV[PQ_bus_mapping[k], PV_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

    end 
end


#R_QQ and X_QQ

for k in PQ_buses

    for m in PQ_buses
        R_QQ[PQ_bus_mapping[k], PQ_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_QQ[PQ_bus_mapping[k], PQ_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

    end 

end


global X_VV_inv = zeros(Float64, n_PV_buses, n_PV_buses)
X_VV_inv = inv(X_VV)
X_VV_inv_minus = -inv(X_VV)







# Calculate the total active power demand (P) and reactive power demand (Q)
global total_p = 0.0
global total_q = 0.0

# Create arrays for the total active power demand (P) and reactive power demand (Q) for each node
total_pgen_pload = Dict{Int,Float64}()
total_qgen_qload = Dict{Int,Float64}()
for row in eachrow(load_data)
    bus = row.bus
    Pload = row.p_mw
    Qload = row.q_mvar
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - (Pload/Ssystem)
    total_qgen_qload[bus] = get(total_qgen_qload, bus, 0.0) - (Qload/Ssystem)
end

# PV buses
Qmin = Dict{Int, Float64}()
Qmax = Dict{Int, Float64}()
for row in eachrow(gen_data)
    bus = row.bus
    Pgen = row.p_mw
    #vm = row.vm_pu
    Qmin[row.bus] = row.QRmin/Ssystem
    Qmax[row.bus] = row.QRmax/Ssystem
    # total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) + Pgen / Ssystem
end

PD = Dict{Int,Float64}()
QD = Dict{Int,Float64}()
for row in eachrow(Downward_data)
    bus = row.Bus
    d_price = row.PD
    d_quantity = row.QD
    PD[bus] = d_price
    QD[bus] = d_quantity/Ssystem
end

PU = Dict{Int,Float64}()
minQ = Dict{Int,Float64}()
maxQ = Dict{Int,Float64}()
for row in eachrow(Upward_data)
    bus = row.Bus
    u_price = row.PU
    u_minquantity = row.MinQ
    u_maxquantity = row.MaxQ
    PU[bus] = u_price
    minQ[bus] = u_minquantity/Ssystem
    maxQ[bus] = u_maxquantity/Ssystem
end

# Create an array to store all the buses that can offer downward flexibility
Downward_set = Int[]
for row in eachrow(Downward_data)
    bus = row.Bus
    if QD[bus] !=0 
        push!(Downward_set, bus)
    end
end

# Create an array to store all the buses that can offer upward flexibility
Upward_set = Int[]
for row in eachrow(Upward_data)
    bus = row.Bus
    if maxQ[bus] !=0 
        push!(Upward_set, bus)
    end
end


# Create dictionaries for the active and reactive power flow in each edge
Rij = Dict{Int64, Float64}()
Xij = Dict{Int64, Float64}()
for row in eachrow(Edges)
    edge = row.idx
    From = row.from_bus
    To = row.to_bus
    R_ij = row.R_pu
    X_ij = row.X_pu

    Rij[edge] = R_ij
    Xij[edge] = X_ij
end

Downward_set = Downward_data[:, :Bus]
buses_except_downward = setdiff(buses, Downward_set)
# Create Upward_set
Upward_set = Upward_data[:, :Bus]
buses_except_upward = setdiff(buses, Upward_set)
########################################################################
########################################################################
########################################################################
########################################################################

@variable(model, V[Nodes])                                  # Variable representing voltage magnitudes of each node
@variable(model, delta[Nodes])                              # Variable representing voltage angles of each node
@variable(model, Q[slack_PV_buses])                         # Variable representing Q production by the slack and the PV buses
@variable(model, production[Upward_set])                    # Variable representing P production by the buses that can offer upward flexibility
@variable(model, consumption[Downward_set]>=0)              # Variable representing P consumption by the buses that can offer downward flexibility
@variable(model, RP_V[PV_buses])                            # Variable representing the matrix Re(Zvv)*pv given on equation (23) for qv
@variable(model, RP_Q[PV_buses])                            # Variable representing the matrix Re(Zvq)*pq given on equation (23) for qv
@variable(model, XQ_Q[PV_buses])                            # Variable representing the matrix Im(Zvq)*qq given on equation (23) for qv
@variable(model, active_power_k[Nodes])
@variable(model, reactive_power_k[Nodes])
@variable(model, f[edges_index])
@variable(model, f_q[edges_index])


# Limits for the Q produced by the slack and the PV buses
@constraint(model, [k in slack_PV_buses], Qmin[k] <= Q[k] <= Qmax[k]) 

# Define the voltage magnitude and angle of the slack bus
@constraint(model, V[slack_bus] == slack_v)                           
@constraint(model, delta[slack_bus] == slack_degree) 

# Limit the P production by the buses that can offer upward flexibility
@constraint(model, UpperBound1[i in Upward_set], production[i] <= maxQ[i])
@constraint(model, UpperBound2[i in Upward_set], production[i] >= minQ[i])

  for k in Nodes 
      if k != slack_bus
          @constraint(model, 0.8 <= V[k] <= 1.2) 
      end
 end


# # #Pij
  @constraint(model, [i in edges_index],f[i] - (Rij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) + Xij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
    / (Rij[i]^2 + Xij[i]^2)  == 0 )
   #Qij
   @constraint(model, [i in edges_index], f_q[i] - (Xij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) - Rij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
    / (Rij[i]^2 + Xij[i]^2)    == 0)



#Flow Limits
  @constraint(model, [i in edges_index],f[i] <=Flowmax_edge_dict[i])
  @constraint(model, [i in edges_index],-f[i] <=Flowmax_edge_dict[i])

  @constraint(model, [i in edges_index],f_q[i] <=Flowmax_edge_dict[i])
  @constraint(model, [i in edges_index],-f_q[i] <=Flowmax_edge_dict[i])



 @constraint(model, Voltage[k in PV_PQ_buses], V[k] == slack_v + (sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in PV_buses)
 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in PV_buses)
 + sum(R_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in PQ_buses)
 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in PQ_buses)) / slack_v)

# Z

 @constraint(model, DeltaConstraint[k in PV_PQ_buses], delta[k] == slack_degree + (sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in PV_buses)
 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in PV_buses)
 + sum(-R_matrix[complete_mapping[k], complete_mapping[i]] * (reactive_power_k[i]) for i in PQ_buses)
 + sum(X_matrix[complete_mapping[k], complete_mapping[i]] * (active_power_k[i]) for i in PQ_buses)) / (slack_v^2))


#Pinjection = sumPij  
#k in Nodes; k == slack_bus 
@constraint(model, TaylorActive[k in Nodes; k == slack_bus], sum((Rij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) + Xij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
  / (Rij[i]^2 + Xij[i]^2) for i in Lines if Edges.from_bus[i] == k) - sum((Rij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) + Xij[i] * (delta[Edges.from_bus[i]] 
  - delta[Edges.to_bus[i]])) / (Rij[i]^2 + Xij[i]^2) for i in Lines if Edges.to_bus[i] == k) == active_power_k[k])

@constraint(model, [k in Nodes; k == slack_bus], sum((Xij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) - Rij[i] * (delta[Edges.from_bus[i]] - delta[Edges.to_bus[i]])) 
/ (Rij[i]^2 + Xij[i]^2) for i in Lines if Edges.from_bus[i] == k) - sum((Xij[i] * (V[Edges.from_bus[i]] - V[Edges.to_bus[i]]) - Rij[i] * (delta[Edges.from_bus[i]] 
- delta[Edges.to_bus[i]])) / (Rij[i]^2 + Xij[i]^2) for i in Lines if Edges.to_bus[i] == k) == reactive_power_k[k])
PV_buses


# @constraint(model, sum(production[k] for k in Upward_set) == -sum(get(total_pgen_pload,k,0) for k in Nodes))

 @constraint(model, reactive[k in PV_buses], 
     Q[k]+get(total_qgen_qload,k,0) == 
     - sum(X_VV_inv[PV_bus_mapping[k], PV_bus_mapping[j]] * 
         (
             sum(R_VV[PV_bus_mapping[j], PV_bus_mapping[i]] * active_power_k[i] for i in PV_buses) +  # RP_V[j]
             sum(R_VQ[PV_bus_mapping[j], PQ_bus_mapping[i]] * active_power_k[i] for i in PQ_buses) +  # RP_Q[j]
             sum(X_VQ[PV_bus_mapping[j], PQ_bus_mapping[i]] * reactive_power_k[i] for i in PQ_buses)  # XQ_Q[j]
            
          )
         for j in PV_buses)
 )
R_matrix
print(X_VV_inv)
X_VV_inv*X_VQ
X_VV_inv*R_VV
X_VV_inv*R_VQ
X_VQ
R_VV
R_VQ
Z



# @constraint(model, production[107] == 0.756719504)
# @constraint(model, production[109] ==0.46314038)



# @constraint(model,  production[28] == 0.0002 )
#@constraint(model,  production[31] == 0.0213778 )
# @constraint(model,  production[15] == 1.325611751)
# @constraint(model,  production[51] == 0.21304498)
#@constraint(model,Production_for_PV[k in PV_buses], production[k] == 0)


@constraint(model, LowerBound1[g in Downward_set], consumption[g] == 0)
 for k in Nodes
#     @constraint(model, active_power_k[k] == get(total_pgen_pload,k,0) + sum(production[i] for i in Upward_set if i == k) - sum(consumption[i] for i in Downward_set if i == k)) 
     @constraint(model, reactive_power_k[k] == sum(Q[i] for i in slack_PV_buses if i == k) + get(total_qgen_qload,k,0))
 end

@constraint(model, active_power[k in Nodes],active_power_k[k] == get(total_pgen_pload,k,0) + sum(production[i] for i in Upward_set if i == k) - sum(consumption[i] for i in Downward_set if i == k)) 


#@objective(model, Min,0)
@objective(model, Max,  -  sum(PU[i]*production[i] for i in Upward_set))
optimize!(model)


@show objective_value(model)

#Δυική για Τιμή
for k in slack_bus
println(dual(TaylorActive[k]))
end

for k in Nodes
     println(dual(active_power[k]))
end

#theme(:wong::Symbol)
#V_magnitude = [value(V[i]) for i in Nodes]
#scatter(V_magnitude, title = "V_magnitude", xlabel = "buses", ylabel = "V_magnitude_per_bus", markersize = 3)
#Delta_deg = [rad2deg(value(delta[i])) for i in Nodes]
#scatter(Delta_deg, title = "Delta_deg", xlabel = "buses", ylabel = "Delta_deg_per_bus", markersize = 3,markercolor = :blue)




PV_buses

results_df = DataFrame(
    Bus = Nodes,
    vm_pu = [value(V[i]) for i in Nodes],
    va_degree = [rad2deg(value(delta[i])) for i in Nodes]
)
show(stdout, "text/plain", results_df)

prod_df = DataFrame(   
    bus = Upward_set,
    production = [value(production[i]) for i in Upward_set],
    pmax = [maxQ[i] for i in Upward_set],
    pmin =[minQ[i] for i in Upward_set],
    PU = [PU[i] for i in Upward_set],
)



Qreact_df = DataFrame(
    Bus = Upward_set,
    q_pu = [value(Q[i]) for i in Upward_set],
    qmin = [Qmin[i] for i in Upward_set],
    qmax =[Qmax[i] for i in Upward_set]
)

# PowerInjection_df = DataFrame(
#     Bus = Nodes,
#     q_injection = [value(reactive_power_k[i]) for i in Nodes],
#     p_injection = [value(active_power_k[i]) for i in Nodes],
    
# )

price_df = DataFrame(
    Bus = buses,
    price = [dual(active_power[j]) for j in buses]
)



###############################################
flow_active_from = []
flow_active_to = []
flow_reactive_from = []
flow_reactive_to = []
for row in eachrow(data)
    From = row.from_bus
    To = row.to_bus
    R_ij = row.R
    X_ij = row.X
    active_power_flow_from = (R_ij * (value(V[From]) - value(V[To])) + X_ij * (value(delta[From]) - value(delta[To]))) / (R_ij^2 + X_ij^2)
    reactive_power_flow_from = (X_ij * (value(V[From]) - value(V[To])) - R_ij * (value(delta[From]) - value(delta[To]))) / (R_ij^2 + X_ij^2)
    active_power_flow_to = (R_ij * (value(V[To]) - value(V[From])) + X_ij * (value(delta[To]) - value(delta[From]))) / (R_ij^2 + X_ij^2)
    reactive_power_flow_to = (X_ij * (value(V[To]) - value(V[From])) - R_ij * (value(delta[To]) - value(delta[From]))) / (R_ij^2 + X_ij^2)
    push!(flow_active_from, active_power_flow_from)
    push!(flow_reactive_from, reactive_power_flow_from)
    push!(flow_active_to, active_power_flow_to)
    push!(flow_reactive_to, reactive_power_flow_to)
end


flows = DataFrame(
    Edges = Lines,
    from_bus = Edges[:,:from_bus],
    to_bus = Edges[:,:to_bus],
    active_flow_from = flow_active_from,
    reactive_flow_from = flow_reactive_from,
    active_flow_to = flow_active_to,
    reactive_flow_to = flow_reactive_to
)

####################################################

#Results for Flows      diko mou
Edges_leng = 1:length(Edges.from_bus)
from_bus = Edges[:,:from_bus]
to_bus = Edges[:,:to_bus]
flows_df = DataFrame(
    Edge = edges_index,
     from_bus = [from_bus[i] for i in Edges_leng],
    flows_to = [to_bus[i] for i in Edges_leng],
    Flow_Active = [value(f[i]) for i in Edges_leng],
    Flow_Reactive = [value(f_q[i]) for i in Edges_leng],
    Flowmax = [Flowmax_edge_dict[i] for i in Edges_leng ]
)


#XLSX.writetable("promised_HV_OH-UGa_Ruan_for_my_code_linear_opf_results.xlsx",  "results" => results_df , "production" => prod_df ,  "Reactive_Production" => Qreact_df , "Power_Injection" => PowerInjection_df,"Flows" => flows)
#XLSX.writetable("2nodes-test_new_linear_approximation_Results.xlsx",  "results" => results_df , "production" => prod_df ,  "Reactive_Production" => Qreact_df , "Power_Injection" => PowerInjection_df)
#XLSX.writetable("paper_different_slack_price_and_fixedproductionPV_linear_approximation_Results.xlsx",  "results" => results_df , "production" => prod_df ,  "Reactive_Production" => Qreact_df , "Power_Injection" => PowerInjection_df)


println(results_df)
println(prod_df)
println(Qreact_df)
# println(PowerInjection_df)

status = termination_status(model)
println(status)   

# sum(value(production[k]) for k in Upward_set)>sum(get(total_pgen_pload,k,0) for k in Nodes)
# sum(value(production[k]) for k in Upward_set)
# sum(get(total_pgen_pload,k,0) for k in Nodes)
# sum(get(total_qgen_qload,k,0) for k in Nodes)
# sum(value(production[k]) for k in Upward_set)+sum(get(total_pgen_pload,k,0) for k in Nodes)

#XLSX.writetable("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας\\Thesis_Writing\\Results\\LINEAR_OPF_Paper_nodes_PV.xlsx",  "results" => results_df , "production" => prod_df ,  "Reactive_Production" => Qreact_df, "Price" => price_df,"Flows"=> flows_df)   














#XLSX.writetable("test.xlsx",  "results" => results_df , "production" => prod_df ,  "Reactive_Production" => Qreact_df , "Power_Injection" => PowerInjection_df)