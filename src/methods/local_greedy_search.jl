using Random

"""
Generate an intra route solution.
- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its delta
"""
function choose_intra_route_move(solution, distance_matrix, mode)
    n = length(solution)
    solution = deepcopy(solution)

    indices = []
    while length(indices) < 2
        idx1 = rand(1:length(solution))
        idx2 = rand(1:length(solution))
        if idx1 < idx2
            push!(indices, idx1)
            push!(indices, idx2)
        end
    end
    idx1, idx2 = indices[1], indices[2]

    if mode == "node"
        solution[idx1], solution[idx2] = solution[idx2], solution[idx1]

        # calculate just delta, not the whole cost of the solution (see: slides 90-91)
        negative_ingredient_node_1 = distance_matrix[solution[mod(idx1-1, n)+1], solution[idx1]] + distance_matrix[solution[idx1], solution[idx1+1]]
        negative_ingredient_node_2 = distance_matrix[solution[idx2-1], solution[idx2]] + distance_matrix[solution[idx2], solution[mod(idx2+1, n)+1]]
        positive_ingredient_node_1 = distance_matrix[solution[mod(idx1-1, n)+1], solution[idx2]] + distance_matrix[solution[idx2], solution[idx1+1]]
        positive_ingredient_node_2 = distance_matrix[solution[idx2-1], solution[idx1]] + distance_matrix[solution[idx1], solution[mod(idx2+1, n)+1]]

        delta = - negative_ingredient_node_1 - negative_ingredient_node_2 + positive_ingredient_node_1 + positive_ingredient_node_2
        
        return solution, delta
    else # edge mode
        # based on slide 93
        solution = solution[1:idx1] + reverse(solution[idx1+1:idx2]) + solution[mod(idx2+1, n)+1:end]

        negative_ingredient = distance_matrix[solution[idx1], solution[idx+1]] + distance_matrix[solution[idx2], solution[mod(idx2+1, n)+1]]
        positive_ingredient = distance_matrix[solution[idx1], solution[idx2]] + distance_matrix[solution[idx+1], solution[mod(idx2+1, n)+1]]

        delta = - negative_ingredient + positive_ingredient
        return solution, delta
    end
end

"""
Generate an inter route solution.
- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node

returns: a local search solution and its delta
"""
function choose_inter_route_move(solution, distance_matrix, cost_vector)
    n = length(solution)
    solution = deepcopy(solution)
    N, _ = size(distance_matrix)
    unvisited = setdiff(Set(1:N), Set(solution))
    unvisited = collect(unvisited)

    candidate_idx = rand(1:length(unvisited))
    candidate = unvisited[candidate_idx]

    substitute_idx = rand(1:length(solution))
    substitute = solution[substitute_idx]
    solution[substitute_idx] = candidate

    # calculate just delta
    negative_ingredient = cost_vector[substitute] + distance_matrix[solution[mod(substitute-1, n)+1], substitute] + distance_matrix[substitute, solution[mod(substitute+1, n)+1]]
    positive_ingredient = cost_vector[candidate] + distance_matrix[solution[mod(substitute-1, n)+1], candidate] + distance_matrix[candidate, solution[mod(substitute+1, n)+1]]
    
    delta = - negative_ingredient + positive_ingredient
    return solution, delta
end



"""
Generate a local search solution given a starting solution and a mode.
- `iterations::Int`: number of iterations
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_greedy_search(iterations, solution, distance_matrix, cost_vector, mode)

    distance_matrix = deepcopy(distance_matrix) 
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)

    for i in 1:iterations
        println("Iteration: ", i)
        new_solution = nothing
        delta = 1000000
        counter = 0

        while delta > 0 && counter < 200
            p = rand()
            println("p: ", p)
            if p < 0.5
                new_solution, delta = choose_intra_route_move(best_solution, distance_matrix, mode)
            else
                new_solution, delta = choose_inter_route_move(best_solution, distance_matrix, cost_vector)
            end

            if delta < 0
                best_solution = deepcopy(new_solution)
                best_cost += delta
            end
            counter += 1 # prevent infinite loop
        end
        println("Best cost: ", best_cost, " delta: ", delta)
    end
    return best_solution, best_cost
end