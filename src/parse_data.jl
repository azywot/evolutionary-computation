using CSV, DataFrames, Distances

"""
# Read CSV data
- `filename::String`: path to CSV file

returns: distance matrix, cost vector, coordinates
"""
function read_data(filename)
    df = CSV.read(filename, DataFrame, header=false)
    rename!(df, [:x, :y, :cost])
    coords = [collect(row) for row in eachrow(hcat(df.x, df.y))]
    distance_matrix = round.(Int, pairwise(Euclidean(), coords))
    for i in 1:size(distance_matrix)[1]
        distance_matrix[i, i] = 1000000
    end

    return distance_matrix, df.cost, coords
end


"""
# Evaluate a solution
- `solution::Vector{Int64}`: a permutation of nodes
- `distance_matrix::Matrix{Int64}`: matrix of distances between nodes
- `cost_vector::Vector{Int64}`: vector of costs of nodes

returns: total value of the solution
"""
function evaluate_solution(solution, distance_matrix, cost_vector)
    total_cost = 0

    for i in eachindex(solution)
        if i == length(solution)
            total_cost += distance_matrix[solution[i], solution[1]]
        else
            total_cost += distance_matrix[solution[i], solution[i+1]]
        end
        total_cost += cost_vector[solution[i]]
    end

    return total_cost
end
