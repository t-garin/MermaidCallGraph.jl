using MermaidCallGraph
readme_path = "README.md"
graph_path = "MermaidCallGraph.md"
mermaid_call_graph()
readme = read(readme_path, String)
graph = read(graph_path, String)
new_readme = replace(readme, r"```mermaid\n.*?\n```"s => graph)
new_readme == readme && error("no mermaid block found in $readme_path")
write(readme_path, new_readme)
rm(graph_path)