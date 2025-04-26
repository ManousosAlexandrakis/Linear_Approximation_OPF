function load_power_system_data_thesis_linear_opf(path::String, filename::String; Ssystem=1)
    global full_path = joinpath(path, filename)
    
    # Load all sheets into DataFrames (global)
    global sgen_data = DataFrame(XLSX.readtable(full_path, "gen"))
    global Edges = DataFrame(XLSX.readtable(full_path, "edges"))
    global bus_data = DataFrame(XLSX.readtable(full_path, "bus"))
    global load_data = DataFrame(XLSX.readtable(full_path, "load"))
    global slack_data = DataFrame(XLSX.readtable(full_path, "ext_grid"))
    global Upward_data = DataFrame(XLSX.readtable(full_path, "Upward"))
    global Downward_data = DataFrame(XLSX.readtable(full_path, "Downward"))

    # Basic system calculations (global)
    global Flowmax_edge_dict = Dict(row.idx => row.FlowMax for row in eachrow(Edges))
    
    # Slack bus data (global)
    global slack_v = slack_data[1, :vm_pu]
    global slack_degree = slack_data[1, :va_degree]
    global slack_bus = slack_data[1, :bus]
    
    # Bus and edge information (global)
    global buses = bus_data[:, :bus]
    global edges_index = Edges[:, :idx]
    
    # Create bus index mapping (global)
    global slack_index = findfirst(bus_data[:, :bus] .== slack_bus)
    global bus_id_to_index = Dict(bus_data[setdiff(1:end, slack_index), :bus] .=> 1:(size(bus_data, 1)-1))
    bus_id_to_index[slack_bus] = size(bus_data, 1)
    
    # System dimensions (global)
    global n = size(bus_data, 1)
    global n_edges = length(Edges.from_bus)
    global Lines = 1:n_edges
    global Edges_leng = 1:length(Edges.from_bus)

    # Load calculations (global)
    global total_p = 0.0
    global total_q = 0.0
    global total_pgen_pload = Dict{Int,Float64}()
    global total_qgen_qload = Dict{Int,Float64}()
    for row in eachrow(load_data)
        bus = row.bus
        Pload = row.p_mw
        Qload = row.q_mvar
        total_pgen_pload[bus] = get(total_pgen_pload, bus, 0.0) - (Pload/Ssystem)
        total_qgen_qload[bus] = get(total_qgen_qload, bus, 0.0) - (Qload/Ssystem)
    end

    # Generator reactive power limits (global)
    global Qmin = Dict{Int, Float64}()
    global Qmax = Dict{Int, Float64}()
    for row in eachrow(sgen_data)
        bus = row.bus
        Qmin[bus] = row.QRmin/Ssystem
        Qmax[bus] = row.QRmax/Ssystem
    end

    # Upward flexibility data (global)
    global PU = Dict{Int,Float64}()
    global minQ = Dict{Int,Float64}()
    global maxQ = Dict{Int,Float64}()
    for row in eachrow(Upward_data)
        bus = row.Bus
        PU[bus] = row.PU
        minQ[bus] = row.MinQ/Ssystem
        maxQ[bus] = row.MaxQ/Ssystem
    end

    # Upward flexibility buses (global)
    global Upward_set = Int[]
    for row in eachrow(Upward_data)
        bus = row.Bus
        if maxQ[bus] != 0 
            push!(Upward_set, bus)
        end
    end

    # Line impedance parameters (global)
    global Rij = Dict{Int64, Float64}()
    global Xij = Dict{Int64, Float64}()
    for row in eachrow(Edges)
        edge = row.idx
        Rij[edge] = row.R_pu
        Xij[edge] = row.X_pu
    end

    println("""
    Power system data loaded successfully:
    - Case: $(splitext(filename)[1])
    - Buses: $n
    - Edges: $(length(Edges_leng))
    - Ssystem: $Ssystem
    """)

    # Return nothing since everything is global
    return nothing
end