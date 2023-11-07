include("./local_greedy_search.jl")


"""
Get nearest (in terms of optimized function) n vertices to the provided node
- `node::Int`: node of interect
- `total_cost_matrix::Matrix{Int}`: matrix of distances+costs between nodes
- `n::Int`: number of nearest vertices to find

returns: n nearest vertices
"""
function get_nearest_n_vertices(node, total_cost_matrix, n = 10)
    neighbours = total_cost_matrix[node, :]
    return partialsortperm(neighbours, 1:n)
end


function evaluate_candidate_moves(n = 10, node, candidates)
    # TODO
end


"""
Generate a local search steepest solution given a starting solution and a mode.
- `solution::Vector{Int}`: initial solution
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `mode::String`: mode of the local search, either "node" or "edge"

returns: a local search solution and its cost
"""
function local_steepest_search_candidate(
    solution,
    distance_matrix,
    cost_vector,
    mode = "edge",
)
    N, _ = size(distance_matrix)
    distance_matrix = deepcopy(distance_matrix)
    cost_vector = deepcopy(cost_vector)
    best_solution = deepcopy(solution)
    best_cost = evaluate_solution(best_solution, distance_matrix, cost_vector)
    # println("Initial cost: ", best_cost)

    node_pairs = collect(Combinatorics.combinations(1:length(solution), 2))
    best_delta = -1
    while best_delta < 0
        best_delta = 0
        best_solution_found = nothing
        unvisited = collect(setdiff(Set(1:N), Set(best_solution)))

        # TODO

        if best_delta < 0
            best_solution = deepcopy(best_solution_found)
            best_cost += best_delta
        end
    end
    # println("Local minimum reached with cost ", best_cost)
    return best_solution
end
