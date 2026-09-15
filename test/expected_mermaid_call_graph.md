```mermaid
flowchart LR
    subgraph "/MermaidCallGraph.jl"
        _MermaidCallGraph_jl_mermaid_call_graph["mermaid_call_graph"]
    end
    subgraph "/edges.jl"
        _edges_jl_get_callee_full_names["get_callee_full_names"]
        _edges_jl_get_edges["get_edges"]
        _edges_jl_get_local_name["get_local_name"]
    end
    subgraph "/genmd.jl"
        _genmd_jl_generate_mermaid_markdown["generate_mermaid_markdown"]
        _genmd_jl_get_full_func_path["get_full_func_path"]
        _genmd_jl_get_node_id["get_node_id"]
    end
    subgraph "/parse.jl"
        _parse_jl_parse["parse"]
    end
    subgraph "/scope.jl"
        _scope_jl_compute_scope_groups["compute_scope_groups"]
        _scope_jl_get_imported_functions_in_scope["get_imported_functions_in_scope"]
        _scope_jl_get_scope_group_functions["get_scope_group_functions"]
    end
    subgraph "/utils.jl"
        _utils_jl_find_jl_files["find_jl_files"]
        _utils_jl_get_children["get_children"]
        _utils_jl_get_full_func_name["get_full_func_name"]
        _utils_jl_get_import_module_name["get_import_module_name"]
        _utils_jl_get_internal_calls_["get_internal_calls!"]
        _utils_jl_get_kind["get_kind"]
        _utils_jl_is_export["is_export"]
        _utils_jl_is_function_call["is_function_call"]
        _utils_jl_is_function_definition["is_function_definition"]
        _utils_jl_is_import["is_import"]
        _utils_jl_is_include["is_include"]
        _utils_jl_unwrap_doc["unwrap_doc"]
    end
    _MermaidCallGraph_jl_mermaid_call_graph --> _edges_jl_get_edges
    _MermaidCallGraph_jl_mermaid_call_graph --> _genmd_jl_generate_mermaid_markdown
    _MermaidCallGraph_jl_mermaid_call_graph --> _parse_jl_parse
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_compute_scope_groups
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_get_imported_functions_in_scope
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_get_scope_group_functions
    _MermaidCallGraph_jl_mermaid_call_graph --> _utils_jl_find_jl_files
    _MermaidCallGraph_jl_mermaid_call_graph --> _utils_jl_get_full_func_name
    _edges_jl_get_callee_full_names --> _edges_jl_get_local_name
    _edges_jl_get_callee_full_names --> _utils_jl_get_children
    _edges_jl_get_callee_full_names --> _utils_jl_get_kind
    _edges_jl_get_edges --> _edges_jl_get_callee_full_names
    _edges_jl_get_edges --> _utils_jl_get_full_func_name
    _edges_jl_get_edges --> _utils_jl_get_kind
    _genmd_jl_generate_mermaid_markdown --> _edges_jl_get_local_name
    _genmd_jl_generate_mermaid_markdown --> _genmd_jl_get_full_func_path
    _genmd_jl_generate_mermaid_markdown --> _genmd_jl_get_node_id
    _parse_jl_parse --> _utils_jl_get_children
    _parse_jl_parse --> _utils_jl_get_internal_calls_
    _parse_jl_parse --> _utils_jl_get_kind
    _parse_jl_parse --> _utils_jl_is_export
    _parse_jl_parse --> _utils_jl_is_function_definition
    _parse_jl_parse --> _utils_jl_is_import
    _parse_jl_parse --> _utils_jl_is_include
    _parse_jl_parse --> _utils_jl_unwrap_doc
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_children
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_full_func_name
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_import_module_name
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_kind
    _utils_jl_get_import_module_name --> _utils_jl_get_children
    _utils_jl_get_internal_calls_ --> _utils_jl_get_children
    _utils_jl_get_internal_calls_ --> _utils_jl_is_function_call
    _utils_jl_is_export --> _utils_jl_get_kind
    _utils_jl_is_function_call --> _utils_jl_get_kind
    _utils_jl_is_function_definition --> _utils_jl_get_kind
    _utils_jl_is_import --> _utils_jl_get_kind
    _utils_jl_is_include --> _utils_jl_get_kind
    _utils_jl_unwrap_doc --> _utils_jl_get_children
    _utils_jl_unwrap_doc --> _utils_jl_get_kind
    _utils_jl_unwrap_doc --> _utils_jl_is_function_definition
```
