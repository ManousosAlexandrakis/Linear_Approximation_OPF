function load_power_system_data_decoupled_opf(filepath::String, filename::String; Ssystem=1)
    # First declare ALL global variables at the beginning
    global gen_data, Edges, bus_data, load_data, slack_data, Upward_data, Downward_data
    global slack_v, slack_degree, slack_bus, buses, edges_index
    global slack_index, bus_id_to_index, Flowmax_dict, connected_buses_dict
    global n, Edges_leng, Nodes, PU, MinQ, MaxQ, Upward_set, buses_except_upward

    # Now load the data
    full_path = joinpath(filepath, filename)
    
    # Initialize all DataFrames
    global gen_data = DataFrame()
    global Edges = DataFrame()
    global bus_data = DataFrame()
    global load_data = DataFrame()
    global slack_data = DataFrame()
    global Upward_data = DataFrame()
    global Downward_data = DataFrame()

    # Load Excel data
    global xlsx = XLSX.readxlsx(full_path)
    global gen_data = DataFrame(XLSX.gettable(xlsx["gen"]))
    global Edges = DataFrame(XLSX.gettable(xlsx["edges"]))
    global bus_data = DataFrame(XLSX.gettable(xlsx["bus"]))
    global load_data = DataFrame(XLSX.gettable(xlsx["load"]))
    global slack_data = DataFrame(XLSX.gettable(xlsx["ext_grid"]))
    global Upward_data = DataFrame(XLSX.gettable(xlsx["Upward"]))
    global Downward_data = DataFrame(XLSX.gettable(xlsx["Downward"]))

    # Process slack bus data
    global slack_v = slack_data[1, :vm_pu]
    global slack_degree = slack_data[1, :va_degree]
    global slack_bus = slack_data[1, :bus]

    # Process buses and edges
    global buses = bus_data[:, :bus]
    global edges_index = Edges[:, :idx]

    # Create bus index mapping
    global slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
    global bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:size(bus_data, 1)-1)
    global bus_id_to_index[slack_bus] = size(bus_data, 1)

    # Create FlowMax dictionary
    global Flowmax_dict = Dict{Tuple{Int, Int}, Float64}()
    for row in eachrow(Edges)
        Flowmax_dict[(row.from_bus, row.to_bus)] = row.FlowMax / Ssystem
        Flowmax_dict[(row.to_bus, row.from_bus)] = row.FlowMax / Ssystem
    end

    # Create connected buses dictionary
    global connected_buses_dict = Dict{Int, Vector{Int}}()
    for row in eachrow(Edges)
        From = row.from_bus
        To = row.to_bus
        
        if !haskey(connected_buses_dict, From)
            connected_buses_dict[From] = Int[]
        end
        push!(connected_buses_dict[From], To)
        
        if !haskey(connected_buses_dict, To)
            connected_buses_dict[To] = Int[]
        end
        push!(connected_buses_dict[To], From)
    end

    # System dimensions
    global n = size(bus_data, 1)
    global Edges_leng = 1:length(Edges.from_bus)

    # Nodes array
    global Nodes = Int[]
    for row in eachrow(bus_data)
        push!(Nodes, row.bus)
    end

    # Generator data dictionaries
    global PU = Dict{Int,Float64}()
    global MinQ = Dict{Int,Float64}()
    global MaxQ = Dict{Int,Float64}()
    for row in eachrow(Upward_data)
        bus = row.Bus
        PU[bus] = row.PU
        MinQ[bus] = row.MinQ / Ssystem
        MaxQ[bus] = row.MaxQ / Ssystem
    end

    # Upward flexibility buses
    global Upward_set = Int[]
    for row in eachrow(Upward_data)
        bus = row.Bus
        MaxQ[bus] != 0 && push!(Upward_set, bus)
    end
    global buses_except_upward = setdiff(buses, Upward_set)


# Create dictionaries to store Minimum and Maximum ReActive Power production limits
global Qmin = Dict{Int, Float64}()
global Qmax = Dict{Int, Float64}()
for row in eachrow(gen_data)
    bus = row.bus
    Pgen = row.p_mw
    #vm = row.vm_pu
    Qmin[row.bus] = row.QRmin/Ssystem
    Qmax[row.bus] = row.QRmax/Ssystem
    # total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) + Pgen / Ssystem
end




    # # Active Load for each bus
global total_p= 0.0
global total_pgen_pload = Dict{Int, Float64}()
for row in eachrow(load_data)
    bus = bus_id_to_index[row.bus]
    Pload = row.p_mw/ Ssystem
    total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - Pload 
    global total_p += total_pgen_pload[bus]
end


# # Create Load_set
global Load_set = Int[]
for row in eachrow(load_data)
    load_buses = row.bus
    push!(Load_set,load_buses)
end
global Buses_without_load =  setdiff(buses, Load_set)


# # Load_Dict
# Add buses and their load values from load_data
global Load_dict = Dict{Int, Float64}()
for row in eachrow(load_data)
    Load_dict[row.bus] = row.p_mw  
end
# Add the additional buses with load 0.0 if they are not already in Load_dict
for bus in Buses_without_load
    Load_dict[bus] = 0.0
end
global Load = Load_dict

# Load_Dict_q
# Add buses and their load_q values from load_data
global Load_dict_q = Dict{Int, Float64}()
for row in eachrow(load_data)
    Load_dict_q[row.bus] = row.q_mvar  
end
# Now, add the additional buses with load 0.0 if they are not already in Load_dict
for bus in Buses_without_load
    Load_dict_q[bus] = 0.0
end
global Load_q = Load_dict_q

    println("""
    Power system data loaded successfully:
    - Case: $(splitext(filename)[1])
    - Buses: $n
    - Edges: $(length(Edges_leng))
    - Ssystem: $Ssystem
    """)
end