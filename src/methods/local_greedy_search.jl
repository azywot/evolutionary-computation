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

        # calculate just delta, not the whole cost of the solution (see: slides 90-91)
        # TODO: check if this is correct, remove comments 
        negative_flow_node_1 = distance_matrix[solution[mod(idx1-2, n)+1], solution[idx1]] + distance_matrix[solution[idx1], solution[idx1+1]]
        # println("negative_flow_node_1: ", distance_matrix[solution[mod(idx1-2, n)+1], solution[idx1]], " ; ", distance_matrix[solution[idx1], solution[idx1+1]])

        negative_flow_node_2 = distance_matrix[solution[idx2-1], solution[idx2]] + distance_matrix[solution[idx2], solution[mod(idx2, n)+1]]
        # println("negative_flow_node_2: ", distance_matrix[solution[idx2-1], solution[idx2]], " ; ",distance_matrix[solution[idx2], solution[mod(idx2, n)+1]])

        positive_flow_node_1 = distance_matrix[solution[mod(idx1-2, n)+1], solution[idx2]] + distance_matrix[solution[idx2], solution[idx1+1]]
        # println("positive_flow_node_1: ", distance_matrix[solution[mod(idx1-2, n)+1], solution[idx2]], " ; ",distance_matrix[solution[idx2], solution[idx1+1]])

        positive_flow_node_2 = distance_matrix[solution[idx2-1], solution[idx1]] + distance_matrix[solution[idx1], solution[mod(idx2, n)+1]]
        # println("positive_flow_node_2: ", distance_matrix[solution[idx2-1], solution[idx1]], " ; ", distance_matrix[solution[idx1], solution[mod(idx2, n)+1]])

        # println("negative_flow_node_1: ", negative_flow_node_1, "; negative_flow_node_2: ", negative_flow_node_2, "; positive_flow_node_1: ", positive_flow_node_1, "; positive_flow_node_2: ", positive_flow_node_2)

        delta = 0
        if mod(idx1 + 1, n) == mod(idx2, n) || mod(idx2 + 1, n) == mod(idx1, n) # edge case
            delta = distance_matrix[solution[idx1], solution[idx2]]
            # println("INDICES", indices)
            # print("positive_flow (adjacent nodes): ", delta)
        end

        delta += positive_flow_node_1 + positive_flow_node_2 - negative_flow_node_1 - negative_flow_node_2
        solution[idx1], solution[idx2] = solution[idx2], solution[idx1]

        return solution, delta

    else # "edge" mode
        if mod(idx1 + 1, n) == mod(idx2, n) || mod(idx2 + 1, n) == mod(idx1, n) # edge case
            return solution, 0 # no change here
        end
        # calculate just delta
        negative_flow = distance_matrix[solution[idx1], solution[idx1+1]] + distance_matrix[solution[idx2], solution[mod(idx2, n)+1]]
        positive_flow = distance_matrix[solution[idx1], solution[idx2]] + distance_matrix[solution[idx1+1], solution[mod(idx2, n)+1]]

        delta = - negative_flow + positive_flow
        solution = vcat(solution[1:idx1], reverse(solution[idx1+1:idx2]), solution[mod(idx2, n)+1:end])

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

    # calculate just delta
    negative_flow = cost_vector[substitute] + distance_matrix[solution[mod(substitute-2, n)+1], substitute] + distance_matrix[substitute, solution[mod(substitute, n)+1]]
    positive_flow = cost_vector[candidate] + distance_matrix[solution[mod(substitute-2, n)+1], candidate] + distance_matrix[candidate, solution[mod(substitute, n)+1]]
    
    delta = - negative_flow + positive_flow
    solution[substitute_idx] = candidate

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
            if p < 0.5
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
            else
                # inter-route; change node from best_solution with a node from unvisited
                unvisited = setdiff(Set(1:N), Set(best_solution))
                unvisited = collect(unvisited)

                candidate_idx = rand(1:length(unvisited))
                substitute_idx = rand(1:length(best_solution))
                candidate = unvisited[candidate_idx]
                indices = [candidate, substitute_idx] # insert candidate in position substitute_idx
                new_solution, delta = generate_inter_route_move(best_solution, distance_matrix, cost_vector, indices)
            end

            if delta < 0
                best_solution = deepcopy(new_solution)
                best_cost += delta
                println("Current best cost: ", best_cost, " delta: ", delta)
            end
            counter += 1 # prevent infinite loop; TODO: clarify this
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
function local_steepest_search(iterations, solution, distance_matrix, cost_vector, mode)

    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    println("Initial cost: ", best_cost)

    for i in 1:iterations
        println("Iteration: ", i)
        best_delta = 1000000
        best_solution_found = nothing

        # all intra-route moves
        for idx1 in 1:length(best_solution)
            for idx2 in idx1+1:length(best_solution)
                indices = [idx1, idx2]
                new_solution, delta = generate_intra_route_move(best_solution, distance_matrix, indices, mode)
                if delta < best_delta
                    best_solution_found = deepcopy(new_solution)
                    best_delta = delta
                    # println("new solution: ", best_solution, "; delta: ", best_delta, "; indices: ", indices)
                end
            end
        end

        # all inter-route moves
        unvisited = setdiff(Set(1:N), Set(best_solution))
        unvisited = collect(unvisited)

        for i in 1:length(best_solution)
            for candidate_node in unvisited
                indices = [candidate_node, i] # insert candidate_node in position i
                new_solution, delta = generate_inter_route_move(best_solution, distance_matrix, cost_vector, indices)
                if delta < best_delta
                    best_solution_found = deepcopy(new_solution)
                    best_delta = delta
                end
            end
        end

        if best_delta < 0
            best_solution = deepcopy(best_solution_found)
            best_cost += best_delta
            println("Current best cost: ", best_cost, " delta: ", best_delta)
        else
            println("Local minimum reached")
            return best_solution, best_cost # local minimum reached
        end
    end
    return best_solution, best_cost
end