using Combinatorics
using Random

"""
Generate an intra route solution.
- `solution::Vector{Int}`: solution
- `dm::Matrix{Int}`: matrix of distances between nodes
- `indices::Vector{Int}`: indices of nodes to be swapped (either the nodes or its edges)
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its delta
"""
function generate_intra_route_move(solution, dm, indices, mode)
    n = length(solution)
    sol = deepcopy(solution)
    i, j = indices[1], indices[2]

    if mode == "node"
        plus_i = dm[sol[j-1], sol[i]] + dm[sol[i], sol[mod(j, n)+1]]
        plus_j = dm[sol[mod(i - 2, n)+1], sol[j]] + dm[sol[j], sol[i+1]]
        minus_i = dm[sol[mod(i - 2, n)+1], sol[i]] + dm[sol[i], sol[i+1]]
        minus_j = dm[sol[j-1], sol[j]] + dm[sol[j], sol[mod(j, n)+1]]

        # println("plus_i ", plus_i)
        # println("plus_j ", plus_j)
        # println("minus_i ", minus_i)
        # println("minus_j ", minus_j)
        # println("-----------------------------")
        delta = plus_i + plus_j - minus_i - minus_j
        sol[i], sol[j] = sol[j], sol[i]

        if mod(i + 1, n) == mod(j, n) || mod(j + 1, n) == mod(i, n) # edge case
            delta += 2 * dm[sol[i], sol[j]]
        end
    elseif mode == "edge"
        if mod(i + 1, n) == mod(j, n) || mod(j + 1, n) == mod(i, n) # edge case
            return solution, 0 # no change here
        end
        # calculate just delta
        negative_flow =
            distance_matrix[solution[i], solution[i+1]] +
            distance_matrix[solution[j], solution[mod(j, n)+1]]
        positive_flow =
            distance_matrix[solution[i], solution[j]] +
            distance_matrix[solution[i+1], solution[mod(j, n)+1]]

        delta = -negative_flow + positive_flow
        solution = vcat(solution[1:i], reverse(solution[i+1:j]), solution[mod(j, n)+1:end])

    end
    return sol, delta
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
    negative_flow =
        cost_vector[substitute] +
        distance_matrix[solution[mod(substitute - 2, n)+1], substitute] +
        distance_matrix[substitute, solution[mod(substitute, n)+1]]
    positive_flow =
        cost_vector[candidate] +
        distance_matrix[solution[mod(substitute - 2, n)+1], candidate] +
        distance_matrix[candidate, solution[mod(substitute, n)+1]]

    delta = -negative_flow + positive_flow
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

    for i = 1:iterations
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
                    i = rand(1:length(best_solution))
                    j = rand(1:length(best_solution))
                    if i < j
                        push!(indices, i)
                        push!(indices, j)
                    end
                end
                new_solution, delta =
                    generate_intra_route_move(best_solution, distance_matrix, indices, mode)
            else
                # inter-route; change node from best_solution with a node from unvisited
                unvisited = setdiff(Set(1:N), Set(best_solution))
                unvisited = collect(unvisited)

                candidate_idx = rand(1:length(unvisited))
                substitute_idx = rand(1:length(best_solution))
                candidate = unvisited[candidate_idx]
                indices = [candidate, substitute_idx] # insert candidate in position substitute_idx
                new_solution, delta = generate_inter_route_move(
                    best_solution,
                    distance_matrix,
                    cost_vector,
                    indices,
                )
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
function local_steepest_search(solution, distance_matrix, cost_vector, mode)

    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    total_cost_matrix = distance_matrix .+ transpose(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    println("Initial cost: ", best_cost)

    node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))
    best_delta = -1
    while best_delta < 0
        best_delta = 0
        best_solution_found = nothing

        for indices in node_pairs
            new_solution, delta =
                generate_intra_route_move(best_solution, total_cost_matrix, indices, mode)
            if delta < best_delta
                best_solution_found = deepcopy(new_solution)
                best_delta = delta
            end
        end
        # println("new solution: ", best_solution, "; delta: ", best_delta)#, "; indices: ", indices)

        # all inter-route moves
        # unvisited = setdiff(Set(1:N), Set(best_solution))
        # unvisited = collect(unvisited)

        # for i in 1:length(best_solution)
        #     for candidate_node in unvisited
        #         indices = [candidate_node, i] # insert candidate_node in position i
        #         new_solution, delta = generate_inter_route_move(best_solution, total_cost_matrix, cost_vector, indices)
        #         if delta < best_delta
        #             best_solution_found = deepcopy(new_solution)
        #             best_delta = delta
        #         end
        #     end
        # end

        if best_delta < 0
            best_solution = deepcopy(best_solution_found)
            best_cost += best_delta
            println("Current best cost: ", best_cost, " delta: ", best_delta)
        end
    end
    println("Local minimum reached")
    return best_solution, best_cost
end
