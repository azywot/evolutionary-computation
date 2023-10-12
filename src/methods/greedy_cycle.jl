using DataFrames

"""
# Generate a greedy solution
- `N::Int`: number of nodes
- `start_nodes::Int`: starting node
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of nodes

returns: a greedy cycle solution
"""
function greedy_cycle(N, start_node, distance_matrix, cost_vector)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)

    current_node = start_node
    solution = [start_node]
    inf = 1000000

    while length(solution) != ceil(N / 2)
        distance_matrix[:, current_node] .= inf
        cost_vector[current_node] = inf

        distances = distance_matrix[current_node, :]
        costs = cost_vector
        summed = distances + costs

        new_node = argmin(summed)
        push!(solution, new_node)
        current_node = new_node
    end
    return solution
end
