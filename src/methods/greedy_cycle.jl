using DataFrames

function greedy_cycle(start_node, distance_matrix, cost_vector)
    current_node = start_node
    cycle = [] # pairs of nodes connected by edge (for plotting)
    inf = 1000000
    total_value = cost_vector[start_node]

    for i in 1:(N/2)
        distance_matrix[:, current_node] .= inf
        cost_vector[current_node] = inf

        distances = distance_matrix[current_node, :]
        costs = cost_vector
        summed = distances + costs

        total_value += minimum(summed)
        new_node = argmin(summed)
        push!(cycle, (current_node, new_node))
        current_node = new_node
    end
    # going back to the start node
    total_value += distance_matrix[start_node, current_node]
    push!(cycle, (current_node, start_node))

    return total_value, cycle
end
