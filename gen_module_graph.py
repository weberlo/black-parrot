# graph_str = """
# /* courtesy Ian Darwin and Geoff Collyer, Softquad Inc. */
# digraph unix {
# 	size="500,500";
# 	node [color=lightblue2, style=filled];
# 	"5th Edition" -> "6th Edition";
# 	"5th Edition" -> "PWB 1.0";
# 	"6th Edition" -> "LSX";
# 	"6th Edition" -> "1 BSD";
# 	"6th Edition" -> "Mini Unix";
# 	"6th Edition" -> "Wollongong";
# 	"6th Edition" -> "Interdata";
# 	"Interdata" -> "Unix/TS 3.0";
# 	"Interdata" -> "PWB 2.0";
# 	"Interdata" -> "7th Edition";
# 	"7th Edition" -> "8th Edition";
# 	"7th Edition" -> "32V";
# 	"7th Edition" -> "V7M";
# 	"7th Edition" -> "Ultrix-11";
# 	"7th Edition" -> "Xenix";
# 	"7th Edition" -> "UniPlus+";
# 	"V7M" -> "Ultrix-11";
# 	"8th Edition" -> "9th Edition";
# 	"1 BSD" -> "2 BSD";
# 	"2 BSD" -> "2.8 BSD";
# 	"2.8 BSD" -> "Ultrix-11";
# 	"2.8 BSD" -> "2.9 BSD";
# 	"32V" -> "3 BSD";
# 	"3 BSD" -> "4 BSD";
# 	"4 BSD" -> "4.1 BSD";
# 	"4.1 BSD" -> "4.2 BSD";
# 	"4.1 BSD" -> "2.8 BSD";
# 	"4.1 BSD" -> "8th Edition";
# 	"4.2 BSD" -> "4.3 BSD";
# 	"4.2 BSD" -> "Ultrix-32";
# 	"PWB 1.0" -> "PWB 1.2";
# 	"PWB 1.0" -> "USG 1.0";
# 	"PWB 1.2" -> "PWB 2.0";
# 	"USG 1.0" -> "CB Unix 1";
# 	"USG 1.0" -> "USG 2.0";
# 	"CB Unix 1" -> "CB Unix 2";
# 	"CB Unix 2" -> "CB Unix 3";
# 	"CB Unix 3" -> "Unix/TS++";
# 	"CB Unix 3" -> "PDP-11 Sys V";
# 	"USG 2.0" -> "USG 3.0";
# 	"USG 3.0" -> "Unix/TS 3.0";
# 	"PWB 2.0" -> "Unix/TS 3.0";
# 	"Unix/TS 1.0" -> "Unix/TS 3.0";
# 	"Unix/TS 3.0" -> "TS 4.0";
# 	"Unix/TS++" -> "TS 4.0";
# 	"CB Unix 3" -> "TS 4.0";
# 	"TS 4.0" -> "System V.0";
# 	"System V.0" -> "System V.2";
# 	"System V.2" -> "System V.3";
# }
# """

# print(graph_str)

import os

# base_file_name = "bp_fe/src/v/bp_fe_top.v"
base_mod_name = 'bp_fe_top'
base_file_name = "bp_fe/src/v/bp_fe_top.v"

bp_mod_to_path = {}
for (dirpath, dirnames, filenames) in os.walk(os.path.dirname(base_file_name)):
    for filename in filenames:
        mod_name = filename.split('.')[0]
        full_path = f'{dirpath}/{filename}'
        bp_mod_to_path[mod_name] = full_path

seen = {base_mod_name}
to_visit = [(base_mod_name, base_file_name)]
graph = {}

while True:
    while len(to_visit) != 0:
        (curr_mod, curr_filename) = to_visit.pop(0)
        if curr_mod not in graph:
            graph[curr_mod] = set()
        with open(curr_filename) as f:
            for line in f:
                line = line.strip()
                if not line or line[0] in ('/', '*'):
                    continue
                for mod in bp_mod_to_path.keys():
                    if line == mod:
                        mod_path = bp_mod_to_path[mod]
                        graph[curr_mod].add(mod)
                        if mod not in seen:
                            to_visit.append((mod, mod_path))
                            seen.add(mod)
    # run until no orphans
    graph_nodes = set()
    for (node, children) in graph.items():
        graph_nodes.add(node)
        graph_nodes |= children
    orphans = set(bp_mod_to_path.keys()) - graph_nodes
    if orphans:
        new_root = orphans.pop()
        new_root_path = bp_mod_to_path[new_root]
        to_visit.append((new_root, new_root_path))
        seen.add(new_root)
    else:
        break

print(f'digraph {base_mod_name} {{')
print('\tsize="500,500";')
print('\tnode [color=lightblue2, style=filled];')
for node in graph:
    children = graph[node]
    if children:
        for child in graph[node]:
            print(f'\t"{node}" -> "{child}";')
    else:
        print(f'\t"{node}";')
print('}')
