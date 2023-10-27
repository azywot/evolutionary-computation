using DataStructures

function parse_stats(dir, filename)
    stats = CSV.read(joinpath("results", dir, filename), DataFrame)
    mean, min, max, t_mean, t_min, t_max = stats[!, "value"]
    mean = round(mean, digits = 2)
    t_mean = round(t_mean, digits = 4)
    t_min = round(t_min, digits = 4)
    t_max = round(t_max, digits = 4)

    val = string(" & ", mean, " (", min, "-", max, ")")
    t_val = string(" & ", t_mean, " (", t_min, "-", t_max, ")")
    return val, t_val
end


dirs = [
    "random_solution",
    "nn_solution",
    "greedy_cycle",
    "greedy_2regret",
    "greedy_2regret_heuristics",
    "local_steepest_search",
    "local_greedy_search",
]
files = ["TSPA_stats.csv", "TSPB_stats.csv", "TSPC_stats.csv", "TSPD_stats.csv"]


latex_string = "Method & TSPA & TSPB & TSPC & TSPD \\\\\\hline\n"
t_latex_string = "Method & TSPA & TSPB & TSPC & TSPD \\\\\\hline\n"
for dir in dirs
    inst = dir
    t_inst = dir
    if dir == "local_steepest_search" || dir == "local_greedy_search"
        for start_method in ["random_solution", "greedy_2regret_heuristics"]
            for mode in ["edge", "node"]
                inst = "$dir" * " $start_method" * " $mode"
                t_inst = inst
                for letter in ["A", "B", "C", "D"]
                    filename = "TSP$letter" * "_$start_method" * "_$mode" * "_stats.csv"
                    val, t_val = parse_stats(dir, filename)
                    inst = string(inst, val)
                    t_inst = string(t_inst, t_val)
                end
                row = string(inst, " \\\\")
                t_row = string(t_inst, " \\\\")
                latex_string = string(latex_string, row, "\n")
                t_latex_string = string(t_latex_string, t_row, "\n")
            end
        end
    else
        for file in files
            val, t_val = parse_stats(dir, file)
            inst = string(inst, val)
            t_inst = string(t_inst, t_val)
        end
        row = string(inst, " \\\\")
        t_row = string(t_inst, " \\\\")
        latex_string = string(latex_string, row, "\n")
        t_latex_string = string(t_latex_string, t_row, "\n")
    end
end

write(joinpath("results", "table_val_l.txt"), latex_string)
write(joinpath("results", "table_time_l.txt"), t_latex_string)
