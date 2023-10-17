using DataStructures


dirs = [
    "random_solution",
    "nn_solution",
    "greedy_cycle",
    "greedy_2regret",
    "greedy_2regret_heuristics",
]
files = ["TSPA_stats.csv", "TSPB_stats.csv", "TSPC_stats.csv", "TSPD_stats.csv"]

latex_string = "Instance & Random solution & Nearest neighbor & Greedy cycle & Greedy 2-regret & G2R heur \\\\\\hline\n"
for file in files
    inst, _ = split(file, "_")
    for dir in dirs
        stats = CSV.read(joinpath("results", dir, file), DataFrame)
        mean, min, max = stats[!, "value"]
        mean = round(mean, digits = 2)
        val = string(" & ", mean, " (", min, "-", max, ")")
        inst = string(inst, val)
    end
    row = string(inst, " \\\\")
    latex_string = string(latex_string, row, "\n")
end

write(joinpath("results", "table.txt"), latex_string)
