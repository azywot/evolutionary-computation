using DataStructures

include("./local_greedy_search.jl")

""" 
Check whether the order of the nodes is preserved in the solution.
- `nodes::Vector{Int}`: nodes
- `solution::Vector{Int}`: solution

returns: true if edge exists, false otherwise
returns: true if order is preserved, false otherwise
"""
function edge_exists_order_preserved(nodes, solution)
    if !(nodes[1] in solution) || !(nodes[2] in solution)
        return false, false
    end
    pos_1 = findfirst(==(nodes[1]), solution)
    pos_2 = findfirst(==(nodes[2]), solution)

    order_preserved = pos_1 + 1 == pos_2
    edge_exists = order_preserved || pos_2 + 1 == pos_1
    return edge_exists, order_preserved
end


function applicable_stored(edge1, edge2, order1, order2)
    if edge1 && edge2
        if !xor(order1, order2)
            return true, false # applicable, not stored
        else
            return false, true # not applicable, stored
        end
    end
    return false, false # not applicable, not stored
end


"""
State whether the solution is applicable to the move.
- `solution::Vector{Int}`: solution
- `move_tuple::Tuple`: move tuple

returns: true if applicable, false otherwise
returns: true if is to be stored, false otherwise
"""
function is_applicable_is_stored(solution, move_tuple)
    nodes, temp, move = move_tuple

    # inter move
    if move == "inter"
        new_node, old_node = nodes
        if !(new_node in solution) && old_node in solution
            node_from, node_to = temp
            edge1 = [node_from, old_node]
            edge2 = [old_node, node_to]
            edge_exists1, order_preserved1 = edge_exists_order_preserved(edge1, solution)
            edge_exists2, order_preserved2 = edge_exists_order_preserved(edge2, solution)
            return applicable_stored(
                edge_exists1,
                edge_exists2,
                order_preserved1,
                order_preserved2,
            )
        end
        return false, false # not applicable, not stored
    end

    # intra move
    edge1, edge2 = [], []
    nodes_succ = temp
    edge1 = [nodes[1], nodes_succ[1]]
    edge2 = [nodes[2], nodes_succ[2]]

    edge_exists1, order_preserved1 = edge_exists_order_preserved(edge1, solution)
    edge_exists2, order_preserved2 = edge_exists_order_preserved(edge2, solution)
    return applicable_stored(edge_exists1, edge_exists2, order_preserved1, order_preserved2)
end


"""
Apply the move to the solution.
- `solution::Vector{Int}`: solution
- `move_tuple::Tuple`: move tuple
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a new solution
"""
function apply_move(solution, move_tuple, distance_matrix, cost_vector, mode)
    nodes, _, move = move_tuple

    if move == "intra"
        node1_index = findfirst(==(nodes[1]), solution)
        node2_index = findfirst(==(nodes[2]), solution)
        new_solution, _ = generate_intra_route_move(
            solution,
            distance_matrix,
            [node1_index, node2_index],
            mode,
        )
        return new_solution
    else # inter move
        node_index = findfirst(==(nodes[2]), solution)
        new_solution, _ = generate_inter_route_move(
            solution,
            distance_matrix,
            cost_vector,
            nodes[1],
            node_index,
        )
        return new_solution
    end
end


"""
Generate a local search steepest solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_search_previous_deltas(solution, distance_matrix, cost_vector, mode = "edge")
    N, _ = size(distance_matrix)
    n = length(solution)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    LM_pq = PriorityQueue{Tuple{Vector{Int64},Vector{Int64},String},Float64}()
    # Priority Queue{(nodes, nodes2, move) delta} it is auto sorted by delta
    # nodes - the nodes that are moved
    # nodes2:
    # in case of "intra" move:
    #   nodes_succ = nodes2
    #   i.e. [nodes[1] -> nodes_succ[1]], [nodes[2] -> nodes_succ[2]]
    # in case of "inter" move:
    #   nodes = new_node, old_node
    #   node_from, node_to = nodes2
    #   i.e. [node_from -> old_node -> node_to] replaced by [node_from -> new_node -> node_to]
    # move - intra/inter

    move_found = true
    changed = Set(1:N)
    while move_found
        move_found = false
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))
        changed_intra = intersect(changed, best_solution)
        node_pairs = collect(Iterators.product(changed_intra, best_solution))

        # intra moves
        for nodes in node_pairs
            move = "intra"
            n1, n2 = nodes
            idx1 = findfirst(==(n1), best_solution)
            idx2 = findfirst(==(n2), best_solution)
            nodes_succ = [best_solution[mod(idx1, n)+1], best_solution[mod(idx2, n)+1]]

            if !haskey(LM_pq, (nodes, nodes_succ, move))
                _, delta = generate_intra_route_move(
                    best_solution,
                    distance_matrix,
                    [idx1, idx2],
                    mode,
                )
                if delta < 0 # brings improvement
                    LM_pq[([n1, n2], nodes_succ, move)] = delta
                end
            end
        end

        # inter moves
        candidate_idx_pairs =
            vec(collect(Iterators.product(unvisited, 1:length(best_solution))))
        for pair in candidate_idx_pairs
            move = "inter"
            nodes = [pair[1], best_solution[pair[2]]]
            nodes_from_to =
                [best_solution[mod(pair[2] - 2, n)+1], best_solution[mod(pair[2], n)+1]]
            if count(x -> x in changed, vcat(nodes, nodes_from_to)) > 1
                if !haskey(LM_pq, (nodes, nodes_from_to, move))
                    _, delta = generate_inter_route_move(
                        best_solution,
                        distance_matrix,
                        cost_vector,
                        pair[1],
                        pair[2],
                    )
                    if delta < 0 # brings improvement
                        LM_pq[(nodes, nodes_from_to, move)] = delta
                    end
                end
            end
        end

        for move_tuple in keys(LM_pq)
            applicable, stored = is_applicable_is_stored(best_solution, move_tuple)

            if applicable
                move_found = true
                best_solution = apply_move(
                    best_solution,
                    move_tuple,
                    distance_matrix,
                    cost_vector,
                    mode,
                )
                nodes, new_nodes, move = move_tuple
                changed = vcat(nodes, new_nodes)
            end

            if !stored
                delete!(LM_pq, move_tuple)
            end

            if move_found
                break
            end
        end
        # println(
        #     "best cost:",
        #     evaluate_solution(best_solution, distance_matrix, cost_vector),
        # )
        # println("LM size: ", length(LM_pq))
    end
    # println("LOCAL MINIMUM REACHED")
    return best_solution
end
