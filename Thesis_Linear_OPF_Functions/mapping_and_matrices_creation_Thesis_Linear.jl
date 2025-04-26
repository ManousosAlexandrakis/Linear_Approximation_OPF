function create_bus_matrices()
    global Nodes = Int[]
    for row in eachrow(bus_data)
        push!(Nodes, row.bus)
    end

    global K_buses = Int[]
    for row in eachrow(sgen_data)
        bus_id = row.bus
        if bus_id != slack_bus && !(bus_id in K_buses)
            push!(K_buses, bus_id)
        end
    end
    global n_K_buses = length(K_buses)

    global L_buses = filter(bus -> !(bus in K_buses) && bus != slack_bus, Nodes)
    global n_L_buses = length(L_buses)

    global slack_K_buses = Int[]
    for row in eachrow(sgen_data)
        bus_id = row.bus
        if !(bus_id in slack_K_buses)
            push!(slack_K_buses, bus_id)
        end
    end

    global K_L_buses = setdiff(Nodes, [slack_bus])
    global n_K_L_buses = length(K_L_buses)

    # Bus mappings
    global slack_map = Dict{Int,Int}()
    slack_map[slack_bus] = size(bus_data, 1)

    global K_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(K_buses))
    global L_bus_mapping = Dict(bus_id => index for (index, bus_id) in enumerate(L_buses))

    global complete_mapping = Dict{Any, Int}()
    for (bus_id, index) in K_bus_mapping
        complete_mapping[bus_id] = index
    end
    for (bus_id, index) in L_bus_mapping
        complete_mapping[bus_id] = index + length(K_buses)
    end
    complete_mapping[slack_bus] = size(bus_data, 1)

    # Admittance and Impedance matrices
    global Y = zeros(Complex, n, n)
    global Z_w_slack = zeros(Complex, n, n)
    for row in eachrow(Edges)
        From_Bus = complete_mapping[row.from_bus]
        To_Bus = complete_mapping[row.to_bus]
        z = row.R_pu + row.X_pu * im
        y_admit = 1 / z
        Y[From_Bus, To_Bus] = -y_admit
        Y[To_Bus, From_Bus] = -y_admit
        Y[From_Bus, From_Bus] += y_admit
        Y[To_Bus, To_Bus] += y_admit
        Z_w_slack[From_Bus, To_Bus] = -1/y_admit
        Z_w_slack[To_Bus, From_Bus] = -1/y_admit
        Z_w_slack[From_Bus, From_Bus] += 1/y_admit
        Z_w_slack[To_Bus, To_Bus] += 1/y_admit
    end

    sl = slack_map[slack_bus]
    Y_without_slack = Y[1:end .!= sl, 1:end .!= sl]
    Z = inv(Y_without_slack)

    global R_matrix = real.(Z)
    global X_matrix = imag.(Z)

    # Partitioned matrices
    global R_KK = zeros(n_K_buses, n_K_buses)
    global X_KK = zeros(n_K_buses, n_K_buses)
    global R_KL = zeros(n_K_buses, n_L_buses)
    global X_KL = zeros(n_K_buses, n_L_buses)
    global R_LK = zeros(n_L_buses, n_K_buses)
    global X_LK = zeros(n_L_buses, n_K_buses)
    global R_LL = zeros(n_L_buses, n_L_buses)
    global X_LL = zeros(n_L_buses, n_L_buses)

    for k in K_buses
        for m in K_buses
            R_KK[K_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_KK[K_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
        end
    end

    for k in K_buses
        for m in L_buses
            R_KL[K_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_KL[K_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
        end 
    end

    for k in L_buses
        for m in K_buses
            R_LK[L_bus_mapping[k], K_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_LK[L_bus_mapping[k], K_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
        end 
    end

    for k in L_buses
        for m in L_buses
            R_LL[L_bus_mapping[k], L_bus_mapping[m]] = R_matrix[complete_mapping[k], complete_mapping[m]]
            X_LL[L_bus_mapping[k], L_bus_mapping[m]] = X_matrix[complete_mapping[k], complete_mapping[m]]
        end 
    end

    global X_KK_inv = inv(X_KK)

    return nothing
end