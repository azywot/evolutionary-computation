using CSV, DataFrames

function parse_solution(instance_data_path, solution_path)
    instance_df = CSV.read(instance_data_path, DataFrame, header = false)
    rename!(instance_df, [:x, :y, :cost])
    solution_df = CSV.read(solution_path, DataFrame)
    nodes = []
    for sol_row in eachrow(solution_df)
        for (index, instance_row) in enumerate(eachrow(instance_df))
            if sol_row.x == instance_row.x && sol_row.y == instance_row.y && sol_row.cost == instance_row.cost
                push!(nodes, index-1)
            end
        end
    end

    nodes_path = split(solution_path, '.')[1] * "_nodes.txt"
    file = open(nodes_path, "w")
    nodes_str = join(nodes, "\n") # changed from ", "
    write(file, nodes_str)
    
    close(file)
end

for letter in ["A", "B", "C", "D"]
    for method in ["ils_0_1"]
        file_path = joinpath(pwd(), "data", "TSP$letter.csv")
        results_path = joinpath(pwd(), "results", method, "TSP$letter" * "_best.csv")
        parse_solution(file_path, results_path)
    end
end
