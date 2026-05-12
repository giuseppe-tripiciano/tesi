import re

def get_string(qlpp_circuit, barriers=False):

    # qlpp pattern regex  
    qlpp_pattern = r'(not|rnot|h|pauli_Y|pauli_Z|phase|pi_8|cnot|ch|c_pauli_Y|c_pauli_Z|swap|tof|cswap|measure)\s*\(\s*(q\(\d+\)(?:\s*,\s*q\(\d+\))*)\s*\)'
    

    # qlpp -> qasm gates mapping
    mapping = {

        # 1-qbit gates
        'not': 'x', 
        'rnot': 'sx',
        'h': 'h',
        'pauli_Y': 'y',
        'pauli_Z': 'z',
        'phase': 's',
        'pi_8': 't',

        # 2-qbit gates
        'cnot': 'cx', 
        'ch': 'ch',
        'c_pauli_Y': 'cy',
        'c_pauli_Z': 'cz',
        'swap': 'swap',

        # 3-qbit gates
        'tof': 'ccx', # rccx
        'cswap': 'cswap',

        # measure
        'measure': 'measure'

        }
    

    # qlpp reg matches set
    qlpp_reg_matches = set()

    # qasm body str list
    qasm_body_str = []

    # qlpp layers parsing
    for qlpp_layer in qlpp_circuit:
        
        # qlpp layer string
        qlpp_layer_str = str(qlpp_layer)

        # qlpp reg matches update
        qlpp_reg_matches.update(re.findall(r'([qc])\((\d+)\)', qlpp_layer_str))

        # qlpp gates
        qlpp_gates = re.findall(qlpp_pattern, qlpp_layer_str)
        
        # qlpp -> qasm gates translation
        if qlpp_gates:
            for qlpp_gate, qlpp_gate_args in qlpp_gates:
                qasm_gate = mapping.get(qlpp_gate)
                if qasm_gate:
                    qlpp_gate_args_idx = re.findall(r'\d+', qlpp_gate_args)
                    if qasm_gate != 'measure':
                        qasm_gate_args = ", ".join([f"q[{i}]" for i in qlpp_gate_args_idx])
                    else:
                        qasm_gate_args = f"q[{qlpp_gate_args_idx[0]}] -> c[{qlpp_gate_args_idx[1]}]"
                    qasm_body_str.append(f"{qasm_gate} {qasm_gate_args};")
            if barriers:
                qasm_body_str.append("barrier q;")
                qasm_body_str.append("")            


    # qubit and bit registers size
    qubit_dim = max([int(qidx) for label, qidx in qlpp_reg_matches if label == 'q'], default=-1) + 1
    bit_dim = max([int(cidx) for label, cidx in qlpp_reg_matches if label == 'c'], default=-1) + 1


    # empty case
    if qubit_dim == 0:
        return ""
        
            
    # qasm body str
    qasm_body_str = "\n".join(qasm_body_str)
    

    # qasm header str list
    qasm_header_str = [
        "OPENQASM 3.0;",
        'include "stdgates.inc";',
    #    "gate rccx ctrl1, ctrl2, tgt {u2(0, pi) tgt;u1(pi/4) tgt;cx ctrl2, tgt;u1(-pi/4) tgt;cx ctrl1, tgt;u1(pi/4) tgt;cx ctrl2, tgt;u1(-pi/4) tgt;u2(0, pi) tgt;}",
        f"qubit[{qubit_dim}] q;",
        ""
    ]

    if bit_dim != 0:
        qasm_header_str.append(f"bit[{bit_dim}] c;")
        qasm_header_str.append("")

    # qasm header str
    qasm_header_str = "\n".join(qasm_header_str) + "\n"


    # qasm code 
    qasm_code = qasm_header_str + qasm_body_str


    return qasm_code

