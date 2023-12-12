include("../methods/random.jl")
include("../methods/local_greedy_search.jl")
include("../parse_data.jl")


mutable struct SolutionInfo
    solution::Vector{Int}
    cost::Int
    edge_similarity_best::Int
    edge_similarity_avg::Float64
    node_similarity_best::Int
    node_similarity_avg::Float64
end


function SolutionInfo(solution::Vector{Int}, cost::Int, edge_similarity_best::Int, node_similarity_best::Int)
    edge_similarity_avg = 0.0
    node_similarity_avg = 0.0
    return SolutionInfo(solution, cost, edge_similarity_best, edge_similarity_avg, node_similarity_best, node_similarity_avg)
end

function Base.show(io::IO, info::SolutionInfo)
    println(io, "SolutionInfo")
    println(io, "solution: ", info.solution)
    println(io, "cost: ", info.cost)
    println(io, "edge similarity (wrt the best solution): ", info.edge_similarity_best)
    println(io, "edge similarity (on average): ", info.edge_similarity_avg)
    println(io, "node similarity (wrt the best solution):", info.node_similarity_best)
    println(io, "node similarity (on average): ", info.node_similarity_avg)
end

"""
Get the set of edges of a solution.

- `solution::Vector{Int}`: solution

returns: a set of edges of the solution (as sorted tuples)
"""
function get_solution_edges_set(solution)
    n = length(solution)
    edges = []
    for i in eachindex(solution)
        if i == n
            nodes = solution[i], solution[1]
        else
            nodes = solution[i], solution[i+1]
        end
        push!(edges, (minimum(nodes), maximum(nodes)))
    end
    return Set(edges)
end


"""
Calculate the similarity between two solutions.

- `solution1::Vector{Int}`: first solution
- `solution2::Vector{Int}`: second solution

returns: a tuple of edge similarity and node similarity
"""
function calculate_solution_similarity(solution1, solution2)

    node_intersection = intersect(Set(solution1), Set(solution2))
    edge_intersection = intersect(get_solution_edges_set(solution1), get_solution_edges_set(solution2))

    return length(edge_intersection), length(node_intersection)
end


"""
Perform similarity tests on a solution.

- `iterations::Int`: number of iterations
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `coords::Vector{Tuple{Int, Int}}`: vector of coordinates of nodes
- `best_solution::Vector{Int}`: best solution
- `method::Function`: method to use to generate the solution
- `verbose::Bool`: whether to print the results

returns: a dataframe containing the results
"""
function perform_similarity_tests(iterations, distance_matrix, cost_vector, best_solution, method = local_greedy_search, verbose = false)
    N = length(cost_vector)
    solution_infos = []

    if verbose
        println("Generating solutions...")
    end
    for i in 1:iterations
        solution = method(random_solution(N), distance_matrix, cost_vector)
        edge_similarity, node_similarity = calculate_solution_similarity(solution, best_solution)
        solution_cost = evaluate_solution(solution, distance_matrix, cost_vector)
        push!(solution_infos, SolutionInfo(solution, solution_cost, edge_similarity, node_similarity))
    end

    if verbose
        println("Calculating average solution similarities...")
    end
    for i in 1:iterations
        for j in i+1:iterations
            edge_similarity, node_similarity = calculate_solution_similarity(solution_infos[i].solution, solution_infos[j].solution)
            solution_infos[i].edge_similarity_avg += edge_similarity/iterations
            solution_infos[i].node_similarity_avg += node_similarity/iterations
            solution_infos[j].edge_similarity_avg += edge_similarity/iterations
            solution_infos[j].node_similarity_avg += node_similarity/iterations
        end
        
    end

    if verbose
        println(solution_infos)
    end

    df = DataFrame()
    fields = filter(f -> f != :solution, fieldnames(SolutionInfo))
    for field in fields
        df[!, Symbol(field)] = getfield.(solution_infos, field)
    end

    return df
end