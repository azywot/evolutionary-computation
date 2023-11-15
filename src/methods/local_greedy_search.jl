using Combinatorics
using Random


"""
Generate an intra route solution.
- `solution::Vector{Int}`: solution
- `dm::Matrix{Int}`: matrix of distances between nodes
- `indices::Vector{Int}`: indices of nodes to be swapped (either the nodes or its edges)
- `mode::String`: mode of the local search, either "node" or "edge"
- `reverse_search::Bool`: whether to reverse edge search or not

returns: a local search solution and its delta
"""
function generate_intra_route_move(solution, dm, indices, mode, reverse_search = false)
    n = length(solution)
    sol = deepcopy(solution)
    i, j = indices[1], indices[2]

    if mode == "node"
        plus_i = dm[sol[j-1], sol[i]] + dm[sol[i], sol[mod(j, n)+1]]
        plus_j = dm[sol[mod(i - 2, n)+1], sol[j]] + dm[sol[j], sol[i+1]]
        minus_i = dm[sol[mod(i - 2, n)+1], sol[i]] + dm[sol[i], sol[i+1]]
        minus_j = dm[sol[j-1], sol[j]] + dm[sol[j], sol[mod(j, n)+1]]

        delta = plus_i + plus_j - minus_i - minus_j
        sol[i], sol[j] = sol[j], sol[i]

        # if nodes are already connected by edge
        if mod(i + 1, n) == mod(j, n) || mod(j + 1, n) == mod(i, n)
            delta += 2 * dm[sol[i], sol[j]]
        end
    elseif mode == "edge"
        # if nodes are already connected by edge
        if mod(i + 1, n) == mod(j, n) || mod(j + 1, n) == mod(i, n)
            return sol, 0
        end

        plus, minus = 0, 0
        if reverse_search
            plus = dm[sol[i], sol[j]] + dm[sol[mod(i - 2, n)+1], sol[j-1]]
            minus = dm[sol[mod(i - 2, n)+1], sol[i]] + dm[sol[j-1], sol[j]]
        else
            plus = dm[sol[i], sol[j]] + dm[sol[i+1], sol[mod(j, n)+1]]
            minus = dm[sol[i], sol[i+1]] + dm[sol[j], sol[mod(j, n)+1]]
        end


        delta = plus - minus
        if reverse_search
            if i == 1
                sol = vcat(reverse(sol[i:j-1]), sol[j:end])
            else
                sol = vcat(sol[1:i-1], reverse(sol[i:j-1]), sol[j:end])
            end
        else
            if j == n
                sol = vcat(sol[1:i], reverse(sol[i+1:j]))
            else
                sol = vcat(sol[1:i], reverse(sol[i+1:j]), sol[j+1:end])
            end
        end
    end
    return sol, delta
end


"""
Generate an inter route solution.
- `solution::Vector{Int}`: solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `new_node::Int`: number of node to be inserted
- `idx::Int`: index at which new node will be inserted

returns: a local search solution and its delta
"""
function generate_inter_route_move(solution, dm, cost_vector, new_node, idx)
    n = length(solution)
    sol = deepcopy(solution)
    old_node = solution[idx]

    plus =
        cost_vector[new_node] +
        dm[sol[mod(idx - 2, n)+1], new_node] +
        dm[new_node, sol[mod(idx, n)+1]]
    minus =
        cost_vector[old_node] +
        dm[sol[mod(idx - 2, n)+1], old_node] +
        dm[old_node, sol[mod(idx, n)+1]]

    delta = plus - minus
    sol[idx] = new_node

    return sol, delta
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
function local_greedy_search(solution, distance_matrix, cost_vector, mode)
    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)

    node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))
    delta = -1
    while delta < 0
        new_solution = nothing
        delta = 0
        intra_count = 0
        inter_count = 0

        node_pairs = shuffle(node_pairs)
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))
        candidate_idx_pairs =
            shuffle(vec(collect(Iterators.product(unvisited, 1:length(best_solution)))))

        while delta >= 0 &&
            (intra_count < length(node_pairs) || inter_count < length(candidate_idx_pairs))
            if rand() < 0.5 && intra_count < length(node_pairs)
                intra_count += 1
                indices = node_pairs[intra_count]
                new_solution, delta =
                    generate_intra_route_move(best_solution, distance_matrix, indices, mode)
            elseif inter_count < length(candidate_idx_pairs)
                inter_count += 1
                candidate_node, idx = candidate_idx_pairs[inter_count]
                new_solution, delta = generate_inter_route_move(
                    best_solution,
                    distance_matrix,
                    cost_vector,
                    candidate_node,
                    idx,
                )
            end
            if delta < 0
                best_solution = deepcopy(new_solution)
            end
        end
    end
    return best_solution
end


"""
Generate a local search steepest solution given a starting solution and a mode.
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
    best_solution = deepcopy(solution)

    node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))
    best_delta = -1
    while best_delta < 0
        best_delta = 0
        best_solution_found = nothing
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))

        for indices in node_pairs
            new_solution, delta =
                generate_intra_route_move(best_solution, distance_matrix, indices, mode)
            if delta < best_delta
                best_solution_found = deepcopy(new_solution)
                best_delta = delta
            end
        end

        candidate_idx_pairs =
            vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            new_solution, delta = generate_inter_route_move(
                best_solution,
                distance_matrix,
                cost_vector,
                pair[1],
                pair[2],
            )
            if delta < best_delta
                best_solution_found = deepcopy(new_solution)
                best_delta = delta
            end
        end

        if best_delta < 0
            best_solution = deepcopy(best_solution_found)
        end
    end
    return best_solution
end
