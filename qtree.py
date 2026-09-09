import graphviz
import uuid
import re
import ast
from IPython.display import HTML


def map_qtree(str, map):
    for old_label, new_label in map.items():
        str = str.replace(old_label,new_label)
    return str


def parse_qtree(str):
    pattern = r"([a-zA-Z_]\w*\((?:[^()]|\([^()]*\))*\))"
    quoted_str = re.sub(pattern, r"'\1'", str)
    return ast.literal_eval(quoted_str)


def draw_qtree(tree, title='Quantum Tree'):
    dot = graphviz.Digraph()
    dot.attr(rankdir='TB')
    dot.attr('node', shape='box', style='rounded, filled', fillcolor='lightgrey')
    dot.attr(labelloc='t') 
    dot.attr(fontname='Helvetica') 
    dot.attr(label=f"""<
                        <FONT POINT-SIZE="20"><B>{title}</B></FONT>
                        <BR/>
                        <FONT POINT-SIZE="14" COLOR="grey">{tree}</FONT>
                        <BR/>
                    >""")  
            
    def draw_qsubtree(subtree, parent_id=None):
        # empty list / None
        if not subtree: 
            return

        if isinstance(subtree, list):
            # current node
            current_val = subtree[0]
            
            # children nodes
            children = subtree[1:] 
        else:
            
            # leaf node
            current_val = subtree
            children = []

        
        node_id = str(uuid.uuid4())
        label = str(current_val)

        if re.match(r"^[a-zA-Z_]+\(\d+\)$", label):
            color = 'white'      
        else:
            color = 'lightblue'  

        dot.node(node_id, label=label, fillcolor=color)

        # link to parent node
        if parent_id:
            dot.edge(parent_id, node_id)

        # recursion on children nodes
        for child in children:
            draw_qsubtree(child, parent_id=node_id)

    # start recursion
    draw_qsubtree(tree)

    svg_dot = dot.pipe(format='svg').decode('utf-8')


    return HTML(f'<div style="width: 100%; height: 100%; display: flex; justify-content: center;">{svg_dot}</div>')