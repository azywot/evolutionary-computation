"""
Calculate the 2-regret of inserting a node into a solution.

- `total_cost_matrix::Matrix{Int}`: matrix of distances between nodes and destination node cost
- `current_solution::Vector{Int}`: current solution
- `new_node::Int`: node to insert
- `weight::Float64`: weight for the regret
returns: the 2-regret of inserting the node
"""
function calculate_2regret(total_cost_matrix, current_solution, new_node, weight)
    n = length(current_solution)
    cost = Inf
    best_insertion = Inf
    second_best_insertion = Inf
    best_insertion_position = 1

    if n == 1
        return -(1 - weight) * total_cost_matrix[current_solution[1], new_node], 2
    end

    for i = 1:n
        prev_vertex = current_solution[i]
        next_vertex = current_solution[mod(i, n)+1]
        cost =
            total_cost_matrix[prev_vertex, new_node] +
            total_cost_matrix[new_node, next_vertex] -
            total_cost_matrix[prev_vertex, next_vertex]
        if cost < best_insertion
            second_best_insertion = best_insertion
            best_insertion = cost
            best_insertion_position = i + 1
        elseif cost < second_best_insertion
            second_best_insertion = cost
        end
    end

    regret = best_insertion - second_best_insertion
    # TODO: ensure it's good: weight * regret - (1-weight) * best_insertion == 2 * weight * second_best_insertion -> does it make sense?
    return weight * regret - (1 - weight) * best_insertion, best_insertion_position
end


"""
Compute a 2-regret greedy solution.

- `N::Int`: number of nodes
- `start_node::Int`: starting node
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `weights::Float64`: weight for the regret
returns: a 2-regret greedy solution
"""
function greedy_2regret(N, start_node, distance_matrix, cost_vector, weight = 1.0)

    total_cost_matrix = deepcopy(distance_matrix) .+ transpose(deepcopy(cost_vector))
    solution = [start_node]
    unvisited = Set(i for i = 1:N if i != start_node)

    while length(solution) != ceil(N / 2)

        best_node = -1
        best_regret = -1000000
        best_insert_position = -1

        for node_candidate in unvisited
            regret, insert_position =
                calculate_2regret(total_cost_matrix, solution, node_candidate, weight)
            if regret > best_regret
                best_regret = regret
                best_node = node_candidate
                best_insert_position = insert_position
            end
        end

        insert!(solution, best_insert_position, best_node)
        delete!(unvisited, best_node)
    end

    return solution
end

"""
Compute a 2-regret greedy solution with heuristics.

- `N::Int`: number of nodes
- `start_node::Int`: starting node
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `weights::Float64`: weights for the cost and regret
returns: a 2-regret greedy solution
"""
function greedy_2regret_heuristics(
    N,
    start_node,
    distance_matrix,
    cost_vector,
    weights = 0.5,
)
    return greedy_2regret(N, start_node, distance_matrix, cost_vector, weights)
end
