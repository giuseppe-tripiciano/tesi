# Decision Models based on Quantum Computing

**M.Sc. thesis in Computer Engineering at the University of Palermo (UniPa) in collaboration with CNR**

**Author:** Giuseppe Tripiciano

**Supervisor:** Prof. Daniele Peri (UniPa)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
**Co-supervisor:** Dr. Filippo Vella (CNR-ICAR)

## Abstract

Quantum computing represents an emerging paradigm for solving decision-making problems; however, gate-level circuit design poses an ever-greater challenge as problem complexity increases. Consequently, research has shifted toward higher-level abstraction tools capable of synthesizing circuits directly from logical formulations. This thesis proposes an operational methodology that integrates logic programming with quantum computing, specifically Grover’s search algorithm, for the design of constraint-based decision models. Building upon and extending the QLPP (*Quantum Logic Programming in Prolog*) framework introduced by Pilato et al. (2025), this work evaluates its effectiveness and potential on an application scenario: the well-known n-queens benchmark problem. The thesis first outlines the theoretical foundations of this methodology, followed by the core architecture and extension of the QLPP framework, including a Python/Qiskit interface for interacting with Prolog and translating circuits into the OpenQASM standard. Finally, the QLPP logic engine and the Python/Qiskit workflow adopted in the target scenario are presented and examined in detail, concluding with a discussion of the results obtained and future directions.

## Key contributions

* Proposed an operational methodology integrating logic programming with quantum computing, specifically Grover’s algorithm, to automatically synthesize decision-making circuits from high-level logical formulations.

* Built upon the QLPP (Quantum Logic Programming in Prolog) framework by Pilato et al. (2025), extending its architecture and logic engine to handle constraint satisfaction problems (CSPs) of varying complexity.

* Interfaced Python/Qiskit with Prolog, extracting circuits returned by QLPP and translating them into OpenQASM 3.0 to ensure hardware-agnostic execution.

* Evaluated QLPP effectiveness and scalability in oracle design for the n-queens benchmark, analyzing Grover's algorithm outcomes via statevector simulation (Qiskit Aer) and decision-diagram simulation (MQT DDSIM).

*Ongoing research on further QLPP development and experimental evaluation, aimed at a scientific publication.*

## Foundational paper

**G.Pilato, F.Vella, T.Brugarino and S.Gaglio. «Towards Quantum Logic Programming».** \
In: 2025 IEEE Conference on Pervasive and Intelligent Computing (PICom). \
[DOI: 10/q9fv](https://doi.org/10/q9fv)

## Repository structure

```
.
├── circuits/
│   └── nqueens_problem.qasm         # OpenQASM 3.0 circuit for the n-queens problem
├── docs/                                                                                           
│   └── tesi.pdf                     # Thesis (in italian)
├── notebooks/
│   ├── 4queens_problem.ipynb        # Gate-level workflow for the queens problem 4x4 
│   └── nqueens_problem.ipynb        # Logic-driven workflow for the n-queens problem
├── prolog/
│   ├── quantumV6.pl                 # Baseline QLPP framework
│   ├── quantumV7.pl                 # Extended QLPP framework 
│   └── nqueens_problem.pl           # N-queens problem QLPP logic engine
├── python/
│   ├── qlpp_to_qasm.py              # QLPP to OpenQASM 3.0 translator
│   └── qtree.py                     # Graphviz renderer of QLPP ASTs
├── .gitignore 
├── LICENSE 
├── README.md                 
└── requirements.txt                 # Python dependencies
```

## Prerequisites & Installation

### System

* **Python >= 3.12** (essential)
* **SWI-Prolog >= 9.0** (essential)
* **Graphviz >= 14.0** (needed for qtree.py)

### Python virtual environment

```bash
# clone the repository
git clone [https://github.com/giuseppe-tripiciano/tesi.git](https://github.com/giuseppe-tripiciano/tesi.git)

# create virtual environment
cd tesi
python -m venv .venv

# activate on Windows
.venv\Scripts\activate

# activate on Linux/macOS 
source .venv/bin/activate

# install dependencies
pip install -r requirements.txt
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.