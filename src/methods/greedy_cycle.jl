using Random


"""
Find nearest and cheapest vertex

- `current_vertex:Int`: current node
- `unvisited::Vector{Int}`: list of unvisited nodes
- `distance_matrix::Matrix{Int}`: matrix of distances+costs between nodes
returns: nearest vertex and corresponding minimal distance
"""
function find_nearest_vertex(current_vertex, unvisited, distances)
    nearest_vertex = -1
    min_distance = Inf

    for vertex in unvisited
        if distances[current_vertex, vertex] < min_distance
            nearest_vertex = vertex
            min_distance = distances[current_vertex, vertex]
        end
    end

    return nearest_vertex, min_distance
end


"""
Find best insert

- `cycle::Vector{Int}`: existing cycle
- `vertex:Int`: current node
- `distance_matrix::Matrix{Int}`: matrix of distances+costs between nodes
returns: best position
"""
function find_best_insertion(cycle, vertex, distances)
    min_increase = Inf
    best_position = 1

    for i = 1:length(cycle)
        prev_vertex = cycle[i]
        next_vertex = cycle[mod(i, length(cycle))+1]

        increase =
            distances[prev_vertex, vertex] + distances[vertex, next_vertex] -
            distances[prev_vertex, next_vertex]

        if increase < min_increase
            min_increase = increase
            best_position = i + 1
        end
    end

    return best_position
end


"""
Compute greedy cycle.

- `N::Int`: number of nodes
- `start_node::Int`: starting node
- `distance_matrix::Matrix{Int}`: matrix of distances between nodes
- `cost_vector::Vector{Int}`: vector of costs of node
- `solution::Vector{Int}`: solution vector
returns: a greedy cycle solution
"""
function greedy_cycle(N, start_node, distances, cost_vector, solution = nothing)
    distances = deepcopy(distances) .+ transpose(deepcopy(cost_vector))

    if isnothing(solution)
        unvisited = Set(1:N)
        cycle = [start_node]
        delete!(unvisited, cycle[1])
    else
        unvisited = setdiff(Set(1:N), Set(solution))
        cycle = deepcopy(solution)
    end
    
    while length(cycle) < ceil(N / 2)
        min_d = Inf
        nearest_vertex = 0
        for node in cycle
            new_v, new_d = find_nearest_vertex(node, unvisited, distances)
            if new_d < min_d
                nearest_vertex = new_v
                min_d = new_d
            end
        end
        best_position = find_best_insertion(cycle, nearest_vertex, distances)

        insert!(cycle, best_position, nearest_vertex)
        delete!(unvisited, nearest_vertex)
    end

    return cycle
end
