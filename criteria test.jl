#Packages
using DataFrames, JuMP,Gurobi
using LinearAlgebra
using XLSX
####################################################################                                 ####################################################################
####################################################################          Data Handling          ####################################################################
####################################################################                                 ####################################################################

#Choose xlsx file you want to read
#filename = "Paper_nodes_PV.xlsx"
#filename = "Name of file.xlsx" , xlsx file should be in the same directory as the code

#Alternative way to choose the file
filename = joinpath("C:\\Users\\alexa\\OneDrive\\Υπολογιστής\\Διπλωματική\\Διπλωματική Κώδικας","3nodes-test_newV21.xlsx")
#filename = joinpath("filepath","The name of the file.xlsx")


#Loading Excel sheets into DataFrames
gen_data = DataFrame(XLSX.readtable(filename, "gen"))
Edges = DataFrame(XLSX.readtable(filename, "edges"))
bus_data = DataFrame(XLSX.readtable(filename, "bus"))
load_data = DataFrame(XLSX.readtable(filename, "load"))
slack_data = DataFrame(XLSX.readtable(filename, "ext_grid"))
Upward_data = DataFrame(XLSX.readtable(filename, "Upward"))
Downward_data = DataFrame(XLSX.readtable(filename, "Downward"))

#Sets explanation:
#K = all generators except slack bus
#L = all buses except slack bus and K

#Sbase of the system
Ssystem = 1

# Create a dictionary mapping edges' idx to FlowMax
Flowmax_edge_dict = Dict{Int, Float64}()
for row in eachrow(Edges)
    Flowmax_edge_dict[row.idx] = row.FlowMax
end

#Data for slack bus(voltage magnitude,voltage degree,bus number)
slack_v = slack_data[1, :vm_pu]  
slack_degree = slack_data[1,:va_degree]
slack_bus = slack_data[1,:bus]

buses = bus_data[:, :bus]
edges_index = Edges[:,:idx]

# Create a dictionary to store the index of each bus
slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
bus_id_to_index[slack_bus] = size(bus_data, 1)

# Total number of buses and edges
n = size(bus_data,1)
n_edges = length(Edges.from_bus)
Lines = 1:n_edges

# Create an array to store all the Nodes
Nodes = Int[]
for row in eachrow(bus_data)
    bus = row.bus
    push!(Nodes, bus)
end

# Create an array to store all the K buses
K_buses = Int[]
for row in eachrow(gen_data)
    bus_id = row.bus
    if bus_id !=slack_bus && !(bus_id in K_buses)
        push!(K_buses, bus_id)
    end
end
n_K_buses = length(K_buses)

# Create an array to store all the L buses
L_buses = filter(bus -> !(bus in K_buses) && bus != slack_bus, Nodes)
n_L_buses = length(L_buses)

# Create an array to store all the K buses along with the slack bus
slack_K_buses = Int[]
for row in eachrow(gen_data)
    bus_id = row.bus
    if !(bus_id in slack_K_buses)
        push!(slack_K_buses, bus_id)
    end
end

# Create an array to store all the K and L buses
K_L_buses = setdiff(Nodes, [slack_bus])
n_K_L_buses = length(K_L_buses)


# Create a map for all the buses(bus names to indexes)
#Slack gets the last index
#K buses get the first indexes
#L buses get the indexes after the K buses

# slack bus has the biggest idx
slack_map = Dict{Int,Int}()
slack_map[slack_bus] = size(bus_data, 1)

# Create a map for all the K buses
#K buses get the first indexes
K_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(K_buses))

# Create a map for all the L buses
#L buses get the indexes after the K buses
L_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(L_buses))

# Combine all mappings into a single comprehensive mapping
complete_mapping = Dict{Any, Int}()
# Add all entries from K_bus_mapping to complete_mapping
for (bus_id, index) in K_bus_mapping
    complete_mapping[bus_id] = index
end
# Add all entries from L_bus_mapping to complete_mapping
for (bus_id, index) in L_bus_mapping
    complete_mapping[bus_id] = index + length(K_buses)
end
# Add the slack bus entry to complete_mapping
complete_mapping[slack_bus] = size(bus_data, 1)


# Create the Mapped Admittance Matrix
global Y = zeros(Complex, n, n)
global Z_w_slack = zeros(Complex, n, n)
for row in eachrow(Edges)
    From_Bus = complete_mapping[row.from_bus]
    To_Bus = complete_mapping[row.to_bus]
    x = row.X_pu
    r = row.R_pu
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
# # Create the Impedance Matrix excluding the slack bus
Z = inv(Y_without_slack)

# Create the R and X Matrices excluding the slack bus
global R_matrix = zeros(Float64, n_K_L_buses, n_K_L_buses)
global X_matrix = zeros(Float64, n_K_L_buses, n_K_L_buses)

R_matrix = real.(Z)
X_matrix = imag.(Z)

#Create Matrices that are used on the paper for the linear approximation
global R_KK = zeros(Float64, n_K_buses, n_K_buses)
global X_KK = zeros(Float64, n_K_buses, n_K_buses)
global R_KL = zeros(Float64, n_K_buses, n_L_buses)
global X_KL = zeros(Float64, n_K_buses, n_L_buses)

global R_LK = zeros(Float64, n_L_buses, n_K_buses)
global X_LK = zeros(Float64, n_L_buses, n_K_buses)
global R_LL = zeros(Float64, n_L_buses, n_L_buses)
global X_LL = zeros(Float64, n_L_buses, n_L_buses)

global X_KK_inv = zeros(Float64, n_K_buses, n_K_buses)

#R_KK and X_KK
for k in K_buses
    for m in K_buses
        R_KK[K_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_KK[K_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
    end
end

#R_KL and X_KL
for k in K_buses
    for m in L_buses
            R_KL[K_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_KL[K_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
    end 
end

#R_LK and X_LK
for k in L_buses
    for m in K_buses
        R_LK[L_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_LK[L_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

    end 
end

#R_LL and X_LL
for k in L_buses

    for m in L_buses
        R_LL[L_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
        X_LL[L_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]

    end 

end

#X_KK_inverted
X_KK_inv = inv(X_KK)


# Calculate the total active power demand (P) and reactive power demand (Q) for each node
global total_p = 0.0
global total_q = 0.0

total_pgen_pload = Dict{Int,Float64}()
total_qgen_qload = Dict{Int,Float64}()
for row in eachrow(load_data)
    bus = row.bus
    Pload = row.p_mw
    Qload = row.q_mvar
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - (Pload/Ssystem)
    total_qgen_qload[bus] = get(total_qgen_qload, bus, 0.0) - (Qload/Ssystem)
end



#Reactive power production limits for each generator bus
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

# Create a dictionary to store generator buses' Marginal Cost, Minimum and Maximum Active Power production limits
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

# Create an array to store all the buses that can offer upward flexibility
Upward_set = Int[]
for row in eachrow(Upward_data)
    bus = row.Bus
    if maxQ[bus] !=0 
        push!(Upward_set, bus)
    end
end

# Create dictionaries for the Resistance and Reactance of each edge
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


total_p = -sum(get(total_pgen_pload, k, 0.0) for k in buses)
total_q = -sum(get(total_qgen_qload, k, 0.0) for k in buses)

R_KK


p_K = zeros(length(K_buses), 1)  # Create a column matrix
for (idx, i) in enumerate(K_buses)
p_K[idx, 1] = min(maxQ[i], total_p)
end
p_K
R_KK*p_K

q_K = zeros(length(K_buses), 1)  # Create a column matrix
for (idx, i) in enumerate(K_buses)
q_K[idx, 1] = min(Qmax[i], total_q)
end
X_KK*q_K

total_p_matrix = zeros(length(L_buses), 1)
for (idx, i) in enumerate(L_buses)
total_p_matrix[idx, 1] = get(total_pgen_pload, idx, 0.0)
end  # Create a column matrix
R_KL*total_p_matrix


total_q_matrix = zeros(length(L_buses), 1)
for (idx, i) in enumerate(L_buses)
total_q_matrix[idx, 1] = get(total_qgen_qload, idx, 0.0)
end  # Create a column matrix
X_KL*total_q_matrix

R_KK*p_K+X_KK*q_K+R_KL*total_p_matrix+X_KL*total_q_matrix