
"""
# Generate a nearest neighbor solution
- `N::Integer`: number of nodes
- `start_nodes::Integer`: starting node
- `distance_matrix::Matrix{Int64}`: matrix of distances between nodes
- `cost_vector::Vector{Int64}`: vector of costs of nodes

returns: a nearest neighbor solution
"""
function nn_solution(N, start_node, distance_matrix, cost_vector)

    distance_matrix = deepcopy(distance_matrix)
    solution = [start_node]

    while length(solution) != ceil(N/2)
        min_index = argmin(distance_matrix[solution[end], :])
        distance_matrix[solution[end], min_index] = 1000000
        distance_matrix[:, solution[end]] .= 1000000
        push!(solution, min_index)
    end

    return solution
end
