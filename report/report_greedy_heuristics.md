# Evolutionary computation - Greedy heuristics
- Zuzanna Gawrysiak 148255
- Agata Żywot 148258

## Problem description
We are given three columns of integers with a row for each node. The first two columns contain x and y coordinates of the node positions in a plane. The third column contains node costs. The goal is to select ceil(0.5 * nodes)  and form a Hamiltonian cycle through this set of nodes such that the
sum of the total length of the path plus the total cost of the selected nodes is minimized.

The distances between nodes are calculated as Euclidean distances rounded mathematically to integer values. The distance matrix should be calculated just after reading an instance and then only the distance matrix (no nodes coordinates) should be accessed by optimization methods to allow
instances defined only by distance matrices.

## Methods implemented 
### Random solution:
```
function random_solution(nodes_number, start_node, distance_matrix)
    k = round(nodes_number / 2 - 1)
    permutation = randomly permute the numbers from 1 to N and select the first k numbers

    if start_node is in permutation:
        while length of permutation is not equal to ceil(nodes_number / 2):
            r = randomly select an integer between 1 and N
            if r is not in permutation:
                add r to the end of permutation
    else:
        add start_node to the beginning of permutation

    return permutation
end
```
### Nearest neighbor:
```
function nn_solution(nodes_number, start_node, distance_matrix)
    Initialize a solution list with start_node as its only element

    while length of the solution list is not equal to ceil(nodes_number / 2):
        min_index = index of the minimum value in the row of the last node in the solution list in the distance_matrix
        Set the distance_matrix value at solution[last element] and min_index to a very large value (e.g., 1000000)
        Set all values in the min_index column of the distance_matrix to a very large value
        Add min_index to the end of the solution list

    Return the solution list
end

```
### Greedy cycle:
```
TODO
```

## Results
Statistics for the cost function and the best solution for each method. 
### Random solution
| Problem instance | min         | max         | mean        | 
| -----------      | ----------- | ----------- | ----------- |
| TSPA             | 238699.0    | 293349.0    | 264329.765  |
| TSPB             | 235387.0    | 291856.0    | 266305.02   |
| TSPC             | 193798.0    | 241475.0    | 215958.905  |
| TSPD             | 190680.0    | 244677.0    | 219239.095  |



| | |
|:-------------------------:|:-------------------------:|
|![Alt text](image.png)| ![Alt text](image-1.png)|
|![Alt text](image-2.png)| ![Alt text](image-3.png)|

### Nearest neighbor
| Problem instance | min         | max         | mean        | 
| -----------      | ----------- | ----------- | ----------- |
| TSPA             | 110035.0    | 125805.0    | 116516.55   |
| TSPB             | 109047.0    | 124759.0    | 116413.93   |
| TSPC             | 62629.0     | 71814.0     | 66329.945   |
| TSPD             | 62967.0     | 71396.0     | 67119.2     |



| | |
|:-------------------------:|:-------------------------:|
|![Alt text](image-4.png)| ![Alt text](image-5.png)|
|![Alt text](image-6.png)| ![Alt text](image-7.png)|


### Greedy cycle
| Problem instance | min         | max         | mean        | 
| -----------      | ----------- | ----------- | ----------- |
| TSPA             | 84471.0     | 95013.0     | 87679.135   |
| TSPB             | 77448.0     | 82631.0     | 79282.58    |
| TSPC             | 56304.0     | 63697.0     | 58872.68    |
| TSPD             | 50335.0     | 59846.0     | 54290.68    |



| | |
|:-------------------------:|:-------------------------:|
|![Alt text](image-8.png)|![Alt text](image-9.png)|
|![Alt text](image-10.png)|![Alt text](image-11.png)|

## Conclusions:
TBD

## Source code:
https://github.com/azywot/evolutionary-computation