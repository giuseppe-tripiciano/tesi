import graphviz
import uuid
import re
import ast
from IPython.display import HTML


def map_qtree(qstr, qmap):
    for old_label, new_label in qmap.items():
        qstr = qstr.replace(old_label,new_label)
    return qstr


def parse_qtree(qstr):
    pattern = r"([a-zA-Z_]\w*\((?:[^()]|\([^()]*\))*\))"
    quoted_qstr = re.sub(pattern, r"'\1'", qstr)
    return ast.literal_eval(quoted_qstr)


def draw_qtree(qtree, title='Quantum Tree'):
    dot = graphviz.Digraph()
    dot.attr(rankdir='TB')
    dot.attr('node', shape='box', style='rounded, filled', fillcolor='lightgrey')
    dot.attr(labelloc='t') 
    dot.attr(fontname='Helvetica') 
    dot.attr(label=f"""<
                        <FONT POINT-SIZE="20"><B>{title}</B></FONT>
                        <BR/>
                        <FONT POINT-SIZE="14" COLOR="grey">{qtree}</FONT>
                        <BR/>
                    >""")  
            
    def draw_qsubtree(qsubtree, parent_id=None):
        # empty list / None
        if not qsubtree: 
            return

        if isinstance(qsubtree, list):
            # current node
            current_val = qsubtree[0]
            
            # children nodes
            children = qsubtree[1:] 
        else:
            
            # leaf node
            current_val = qsubtree
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
    draw_qsubtree(qtree)

    svg_dot = dot.pipe(format='svg').decode('utf-8')


    return HTML(f'<div style="width: 100%; height: 100%; display: flex; justify-content: center;">{svg_dot}</div>')


if __name__ == "__main__":
    import tempfile
    import webbrowser

    # insert a QLPP qtree
    raw_qtree = '[cnot(q(0),q(4)),[q(0)],[cnot(q(1),q(4)),[q(1)],[cnot(q(2),q(4)),[q(2)],[cnot(q(3),q(4)),[q(3)],[q(4)]]]]]'

    mapped_qtree = map_qtree(raw_qtree, {"q(0)": "c(0)", "q(1)": "c(1)", "q(2)": "c(2)", "q(3)": "c(3)", "q(4)": "c(4)"})
    parsed_qtree = parse_qtree(mapped_qtree)
    html_qtree = draw_qtree(parsed_qtree, title="Quantum Syntax Tree")

    with tempfile.NamedTemporaryFile("w", delete=False, suffix=".html", encoding="utf-8") as f:
        f.write(html_qtree.data)
        webbrowser.open(f"file://{f.name}")

