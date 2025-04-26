function create_admittance_matrix_decoupled_opf()
    # Declare global variables
    global y = zeros(ComplexF64, n, n)
    global Y = zeros(ComplexF64, n, n)
    global B = zeros(Float64, n, n)

    # Primitive admittance matrix calculation
    for row in eachrow(Edges)
        From_Bus = bus_id_to_index[row.from_bus]
        To_Bus = bus_id_to_index[row.to_bus]
        x = row.X_pu
        r = 0.0  # Forcing resistance to zero per your original code
        z = r + x * im
        y[From_Bus, To_Bus] = 1/z
        y[To_Bus, From_Bus] = 1/z
    end

    # # Create Y matrix
global y = zeros(Complex, n, n)

for row in eachrow(Edges)
    From_Bus = bus_id_to_index[row.from_bus]
    To_Bus = bus_id_to_index[row.to_bus]
    x = row.X_pu
    row.R_pu = 0
    r = row.R_pu
    local z = r + x .* im
    y[From_Bus,To_Bus] = 1 ./ z[1]
    y[To_Bus,From_Bus] = 1 ./ z[1]
end

Y = zeros(Complex, n, n)

for k in Nodes
    Y[bus_id_to_index[k], bus_id_to_index[k]] =  sum((y[bus_id_to_index[k], bus_id_to_index[m]] ) for m in connected_buses_dict[k])
end

for k in Nodes
    for m in connected_buses_dict[k]
        Y[bus_id_to_index[k],bus_id_to_index[m]] = -y[bus_id_to_index[k], bus_id_to_index[m]]
    end
end

# println("Admittance Matrix (Ykk):")
# println(Y)

# # Create B matrix
B = imag.(Y)

    # Print summary
    println("\nAdmittance matrices calculated successfully:")
    println("- Primitive admittance matrix (y) size: ", size(y))
    println("- Bus admittance matrix (Y) size: ", size(Y))
    println("- Susceptance matrix (B) size: ", size(B))
    
    return (y=y, Y=Y, B=B)  # Return as named tuple for optional use
end