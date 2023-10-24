using Random

"""
Generate an intra route solution.
- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `indices::Vector{Int}`: indices of nodes to be swapped (either the nodes or its edges)
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its delta
"""
function generate_intra_route_move(solution, distance_matrix, indices, mode)
    n = length(solution)
    solution = deepcopy(solution)
    idx1, idx2 = indices[1], indices[2]

    if mode == "node"
        solution[idx1], solution[idx2] = solution[idx2], solution[idx1]

        # calculate just delta, not the whole cost of the solution (see: slides 90-91)
        negative_flow_node_1 = distance_matrix[solution[mod(idx1-1, n)+1], solution[idx1]] + distance_matrix[solution[idx1], solution[idx1+1]]
        negative_flow_node_2 = distance_matrix[solution[idx2-1], solution[idx2]] + distance_matrix[solution[idx2], solution[mod(idx2+1, n)+1]]
        positive_flow_node_1 = distance_matrix[solution[mod(idx1-1, n)+1], solution[idx2]] + distance_matrix[solution[idx2], solution[idx1+1]]
        positive_flow_node_2 = distance_matrix[solution[idx2-1], solution[idx1]] + distance_matrix[solution[idx1], solution[mod(idx2+1, n)+1]]

        delta = - negative_flow_node_1 - negative_flow_node_2 + positive_flow_node_1 + positive_flow_node_2
        
        return solution, delta

    else # edge mode
        # based on slide 93
        solution = solution[1:idx1] + reverse(solution[idx1+1:idx2]) + solution[mod(idx2+1, n)+1:end]

        # calculate just delta
        negative_flow = distance_matrix[solution[idx1], solution[idx+1]] + distance_matrix[solution[idx2], solution[mod(idx2+1, n)+1]]
        positive_flow = distance_matrix[solution[idx1], solution[idx2]] + distance_matrix[solution[idx+1], solution[mod(idx2+1, n)+1]]

        delta = - negative_flow + positive_flow
        return solution, delta
    end
end

"""
Generate an inter route solution.
- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `indices::Vector{Int}`: indices of nodes to be swapped

returns: a local search solution and its delta
"""
function generate_inter_route_move(solution, distance_matrix, cost_vector, indices)
    n = length(solution)
    solution = deepcopy(solution)

    candidate = indices[1]
    substitute_idx = indices[2]
    substitute = solution[substitute_idx]
    solution[substitute_idx] = candidate

    # calculate just delta
    negative_flow = cost_vector[substitute] + distance_matrix[solution[mod(substitute-1, n)+1], substitute] + distance_matrix[substitute, solution[mod(substitute+1, n)+1]]
    positive_flow = cost_vector[candidate] + distance_matrix[solution[mod(substitute-1, n)+1], candidate] + distance_matrix[candidate, solution[mod(substitute+1, n)+1]]
    
    delta = - negative_flow + positive_flow
    return solution, delta
end



"""
Generate a local search greedy solution given a starting solution and a mode.
- `iterations::Int`: number of iterations
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_greedy_search(iterations, solution, distance_matrix, cost_vector, mode)
    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    println("Initial cost: ", best_cost)

    for i in 1:iterations
        println("Iteration: ", i)
        new_solution = nothing
        delta = 1000000
        counter = 0

        while delta > 0 && counter < 200
            p = rand()
            # println("p: ", p)
            if p <= 2 # generate_intra_route_move with "node" mode
                # intra-route; change edge or node within best_solution
                indices = []
                while length(indices) < 2
                    idx1 = rand(1:length(best_solution))
                    idx2 = rand(1:length(best_solution))
                    if idx1 < idx2
                        push!(indices, idx1)
                        push!(indices, idx2)
                    end
                end
                new_solution, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode)
                println(best_cost)
            else
                # inter-route; change node from best_solution with a node from unvisited
                unvisited = setdiff(Set(1:N), Set(best_solution))
                unvisited = collect(unvisited)

                candidate_idx = rand(1:length(unvisited))
                substitute_idx = rand(1:length(best_solution))
                candidate = unvisited[candidate_idx]
                indices = [candidate, substitute_idx]
                new_solution, delta = generate_inter_route_move(best_solution, distance_matrix, cost_vector, indices)
            end

            if delta < 0
                best_solution = deepcopy(new_solution)
                println("Old best cost: ", best_cost, "; delta: ", delta, "; old best cost evalueated: ", evaluate_solution(best_solution, distance_matrix, cost_vector))
                best_cost += delta
                println("New best cost: ", best_cost, "; new best cost evalueated: ", evaluate_solution(best_solution, distance_matrix, cost_vector))
                println("Best cost: ", best_cost, " delta: ", delta)
            end
            counter += 1 # prevent infinite loop
        end
    end
    return best_solution, best_cost
end



"""
Generate a local search steepest solution given a starting solution and a mode.
- `iterations::Int`: number of iterations
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_steepest_search()
    # TODO: by analogy with local_greedy_search
end