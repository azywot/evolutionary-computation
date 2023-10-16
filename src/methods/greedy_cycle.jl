using Random

# Function to find the nearest unvisited vertex
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

# Function to find the vertex to insert that minimizes the increase in cycle length
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

# Pseudocode implementation
function greedy_cycle(N, start_node, distances, cost_vector)
    distances = deepcopy(distances) .+ transpose(deepcopy(cost_vector))
    unvisited = Set(1:N)
    cycle = [start_node]
    delete!(unvisited, cycle[1])

    while length(cycle) < ceil(N / 2)
        current_vertex = cycle[end]
        nearest_vertex, _ = find_nearest_vertex(current_vertex, unvisited, distances)
        best_position = find_best_insertion(cycle, nearest_vertex, distances)

        insert!(cycle, best_position, nearest_vertex)
        delete!(unvisited, nearest_vertex)
    end

    return cycle
end

# Example usage
# Replace this with your actual distance matrix
# distances = [0 29 20 21; 29 0 15 12; 20 15 0 17; 21 12 17 0]
# cost_vector = [5, 8, 7, 4]

# tour = tsp_algorithm(distances, cost_vector)
# println("Optimal tour: ", tour)
