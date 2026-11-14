:- op(120, yfx, qAND).
:- op(150, yfx, [qOR, qXOR, qCZ, qCS]).
:- op(100, fy, [qH, qNOT, qRNOT, qY, qZ, qS, qT]).

q_operator(X) :- member(X, [qAND, qOR, qXOR, qH, qNOT, qRNOT, qSWAP, qCSWAP, qY, qZ, qS, qT, qCZ, qCS, qCSWAP, qCZ, qCS]).


gate(qAND, tof, 3).
gate(qXOR, cnot, 2).
gate(qH, h,1).
gate(qNOT, not, 1).
gate(qRNOT, rnot, 1).
gate(qSWAP, swap, 2).
gate(qCSWAP,fredkin, 3).
gate(qY,pauli_Y,1).
gate(qZ,pauli_Z,1).
gate(qS,phase,1).
gate(qT,pi_8,1).
gate(qCZ,c_pauli_Z,2).
gate(qCS,c_phase,2).



% Number sequence generator
%
:- asserta(qnn(0)).
:- asserta(cnn(0)).

qbit_number(N) :-
    retract(qnn(N)),
    Np1 is N + 1,!,
    asserta(qnn(Np1)),!.

reset_qbit_number :-
    retract(qnn(_)),
    asserta(qnn(0)).

cbit_number(N) :-
    retract(cnn(N)),
    Np1 is N + 1,!,
    asserta(cnn(Np1)),!.

reset_cbit_number :-
    retract(cnn(_)),
    asserta(cnn(0)).


% Expression translator
%
translate([q(N),q(N),[q(N)|_]], [q(N)]).
translate([Formula,q(N),Qbits], [Layer_gate, Left]) :-
    Formula =.. [Op, LF],
    last(Qbits,q(N)),
    q_operator(Op), 
    gate(Op,Gate,1),
    Layer_gate =.. [Gate, q(N1)],
    translate([LF,q(N1),Qbits], Left).
translate([LF qAND RF,q(N3),[q(N1), q(N2), q(N3)|_]], [tof(q(N1),q(N2),q(N3)), Left, Right]) :-
    translate([LF,q(N1),[q(N1)|_]], Left),
    translate([RF,q(N2),[q(N2)|_]], Right).
translate([Formula,q(N2),[q(N1),q(N2)|_]], [Layer_gate, Left, Right]) :-
    Formula =.. [Op, LF, RF],
    q_operator(Op), 
    gate(Op,Gate,2),
    translate([LF,q(N1),QbitsL], Left),
    translate([RF,q(N2),QbitsR], Right),
    append(_,[q(N1)],QbitsL), 
    append(_,[q(N2)],QbitsR),
    Layer_gate =.. [Gate, q(N1), q(N2)].


value(N) :- var(N), qbit_number(N),!.
value(_).



normalize(q(N), q(N)) :- !.
normalize(Arg1_in qOR Arg2_in, qNOT (qNOT Arg1_out qAND qNOT Arg2_out)) :- !,
    normalize(Arg1_in, Arg1_out), normalize(Arg2_in, Arg2_out).
normalize(Formula_in, Formula_out):- 
    Formula_in =.. [Op, Arg_in], 
    normalize(Arg_in, Arg_out),
    Formula_out =.. [Op, Arg_out].
normalize(Formula_in, Formula_out) :- 
    Formula_in =.. [Op, Arg1_in, Arg2_in], 
    normalize(Arg1_in, Arg1_out), 
    normalize(Arg2_in, Arg2_out), 
    Formula_out =.. [Op, Arg1_out, Arg2_out].


circuit_tree(Formula,Qbit,Circuit_tree) :- normalize(Formula, Norm_formula), !,
    translate([Norm_formula,Qbit,_], Circuit_tree).

qcircuit(Formula,Qbit,Layers) :-
    circuit_tree(Formula,Qbit,Tree), layers(Tree, Layers).

level_gates([],[]).
level_gates([[Gate|_]| Rest_trees],[Gate|Rest_gates]) :-
              level_gates(Rest_trees,Rest_gates).

subtrees([],[]).
subtrees([[_|Subs]|Rest_trees], Subtrees) :-
    subtrees(Rest_trees, Other_subs), append(Subs, Other_subs, Subtrees).


layers(Tree, Levels) :- all_layers([Tree], Levels).

all_layers([],[]).
all_layers(Tree_list,[Gates|Other_levels]) :-
    level_gates(Tree_list,Gates),
    subtrees(Tree_list,Subtrees),
    all_layers(Subtrees,Other_levels).


% Build a register
%
make_qbits(0,[]).
make_qbits(N,[q(M):q(M)|RRest]) :-
    N>0,
    Nm1 is N-1,
    qbit_number(M),
    make_qbits(Nm1,RRest).

make_cbits(0,[]).
make_cbits(N,[c(M):c(M)|RRest]) :-
    N>0,
    Nm1 is N-1,
    cbit_number(M),
    make_cbits(Nm1,RRest).


% Fill_Register with expressions
% %
fill_register(Reg,[],Reg).
fill_register([],_,[]).
fill_register([Bit:_|Rin],[Bit:Exp|Rest],[Bit: Exp|Rout]) :-
    member(Bit,[q(_),c(_)]),!,
    fill_register(Rin,Rest,Rout).
fill_register([BitK:Val|Rin],[Bit:Exp|Rest],[BitK:Val|Rout]) :-
    BitK \= Bit,
    fill_register(Rin,[Bit:Exp|Rest],Rout).





apply_operator(QOP2,[Qbit1,Qbit2],RegIn,RegOut) :-
    q_operator(QOP2),gate(QOP2,Gate,2),
    make_exps(Gate,[Qbit1:ExP1,Qbit2:Exp2]),
    fill_register(RegIn,[Qbit1:ExP1,Qbit2:Exp2],RegOut).
apply_operator(QOP3,[Qbit1,Qbit2,Qbit3],RegIn,RegOut) :-
    q_operator(QOP3),gate(QOP3,Gate,3),
    make_exps(Gate,[Qbit1:Exp1,Qbit2:Exp2, Qbit3:Exp3]),
    fill_register(RegIn,[Qbit1:Exp1,Qbit2:Exp2,Qbit3:Exp3],RegOut).
apply_operator(measurement, [Qbit,Cbit],QRegister,CRegister,RegOut) :-
    append(QRegister,CRegister,RegIn),
    make_exps(measurement,[Qbit:Exp1,Cbit:Exp2]),
    fill_register(RegIn,[Qbit:Exp1,Cbit:Exp2],RegOut).



make_exps(swap,[Qbit1:[swap(Qbit2,Qbit1)],Qbit2:[swap(Qbit1,Qbit2)]]).
make_exps(fredkin,[Qbit1:Qbit1,Qbit2:[cswap(Qbit1,Qbit3,Qbit2)],Qbit3:[cswap(Qbit1,Qbit2,Qbit3)]]).
make_exps(measurement,[Qbit:[measured(Cbit,Qbit)],Cbit:[measure(Qbit,Cbit)]]).
make_exps(c_pauli_Z,[Qbit1:Qbit1,Qbit2:[c_pauli_Z(Qbit1,Qbit2)]]).
make_exps(c_phase,[Qbit1:Qbit1,Qbit2:[c_phase(Qbit1,Qbit2)]]).



% Transform QR1 -> QR2
%
% Compile the expressions in QR1
%
transform([],[]).
transform([q(K):Exp|Rin],[q(K): Circ|Rout]) :- !,
    qcircuit(Exp,q(K),Circ), transform(Rin,Rout).




% Build a circuit
%  build_circuit(Register,Exp/Op,Circuit)
%
build_circuit(QRegister,exp(Exp),[FCircuit]) :-
    fill_register(QRegister,Exp,QRfilled),
    transform(QRfilled,Circuit),
    filter(Circuit,FCircuit).
build_circuit(QRegister,operator(QOP),Qbits,[Circuit]) :-
    apply_operator(QOP,Qbits,QRegister,Circuit).


filter([],[]).
filter([q(N):q(N)|Rest],[q(N):q(N)|FRest]) :- !,
    filter(Rest,FRest).
filter([q(N):[[q(N)]]|Rest],[q(N):q(N)|FRest]) :- !,
    filter(Rest,FRest).
filter([q(N):Circ|Rest],[q(N):FCirc|FRest]) :-
    reverse(Circ,[_|FCirc]),
    filter(Rest,FRest).



% Complete a circuit (add new ports at the end)
%   complete_circuit(Register,Previous,Exp/Op,New)
%
complete_circuit(QRegister,PCircuit,exp(Exp),NCircuit) :-
    fill_register(QRegister,Exp,QRfilled),
    transform(QRfilled,Add_Circuit),
    filter(Add_Circuit,FAddCircuit),
    append(PCircuit,[FAddCircuit],NCircuit).
complete_circuit(QRegister,PCircuit,operator(QOP),Qbits,NCircuit) :-
    apply_operator(QOP,Qbits,QRegister,QRout),
    append(PCircuit,[QRout],NCircuit).
complete_circuit(QRegister,CRegister,PCircuit,measurement,[Qbit,Cbit],NCircuit) :-
    apply_operator(measurement,[Qbit,Cbit],QRegister,CRegister,OutCircuit),
    append(PCircuit,[OutCircuit],NCircuit).



% Test
%

query1(QRout) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,exp([q(0): qNOT (q(2) qXOR q(0))]),QRout).

query2(NC) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,exp([q(0): qNOT (q(2) qXOR q(0))]),QRout),
    complete_circuit(QRin,QRout,exp([q(1):q(2) qXOR q(1)]),NC).

query3(QRout) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,operator(qSWAP),[q(0),q(1)],QRout).

query4(NCircuit) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,operator(qSWAP),[q(0),q(1)],QRout),
    complete_circuit(QRin,QRout,operator(qCSWAP),[q(0),q(1),q(2)],NCircuit).

query5(NCircuit) :-
    reset_qbit_number,
    reset_cbit_number,
    make_qbits(2,QRin),
    make_cbits(2,CRin),
    build_circuit(QRin,exp([q(0):qH q(0)]),QRout),
    complete_circuit(QRin,QRout,exp([q(1):q(0) qXOR q(1)]),NC1),
    complete_circuit(QRin,CRin,NC1,measurement,[q(0),c(0)],NC2),
    complete_circuit(QRin,CRin,NC2,measurement,[q(1),c(1)],NCircuit).

query6(QRout) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,exp([q(0): qT (q(2) qXOR q(0))]),QRout).

query7(NCircuit) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,operator(qSWAP),[q(0),q(1)],QRout),
    complete_circuit(QRin,QRout,operator(qCS),[q(1),q(2)],NCircuit).

query8(NC) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,exp([q(0): qNOT (q(2) qXOR q(0))]),QRout),
    complete_circuit(QRin,QRout,exp([q(2):q(0) qAND q(1)]),NC).

query9(NC) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,exp([q(1): qNOT (q(2) qXOR q(1))]),NC1),
    complete_circuit(QRin,NC1,exp([q(0):q(2) qXOR q(0)]),NC2),
    complete_circuit(QRin,NC2,operator(qSWAP),[q(0),q(1)],NC).

query10(NC) :-
    reset_qbit_number,
    make_qbits(4,QRin),
    build_circuit(QRin,exp([q(2): q(3) qXOR q(2)]),NC1),
    complete_circuit(QRin,NC1,exp([q(0): qNOT (q(2) qXOR q(0))]),NC2),
    complete_circuit(QRin,NC2,exp([q(1): qNOT (q(2) qXOR q(1))]),NC).

% Tests:
%
% Query:    query1(QR).
%
% Answer QR = [[q(0):[[cnot(q(2), q(0))],[not(q(0))]],q(1):q(1),q(2):q(2)]]
%
%
% Query:    query2(QR).
%
% Answer:   QR = [[q(0):[[cnot(q(2), q(0))], [not(q(0))]], q(1):q(1), q(2):q(2)],
%                 [q(0):q(0), q(1):[[cnot(q(2), q(1))]], q(2):q(2)]]
%
%
% Query:   query3(QR)
%
% Answer:  QR = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)]]
%
%
% Query:  query4(NC)
%
% Answer: NC = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)],
%               [q(0):q(0),
%                q(1):[cswap(q(0), q(2), q(1))],
%                q(2):[cswap(q(0), q(1), q(2))]]]
%
%
% Query:  query5(C)  -- Entanglement
%
% Answer: C = [[q(0):[[h(q(0))]], q(1):q(1)],
%              [q(0):q(0), q(1):[[cnot(q(0), q(1))]]],
%              [q(0):[measured(c(0), q(0))], q(1):q(1), c(0):[measure(q(0), c(0))], c(1):c(1)],
%              [q(0):q(0), q(1):[measured(c(1), q(1))], c(0):c(0),c(1):[measure(q(1), c(1))]]]
%
%
% Query:  query6(C)
%
% Answer: C = [[q(0):[[cnot(q(2), q(0))], [pi_8(q(0))]],q(1):q(1),q(2):q(2)]]
%
%
% Query:  query7(C).
%
% Answer: C = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)], [q(0):q(0), q(1):q(1), q(2):[c_phase(q(1), q(2))]]]
%
% Query:  query8(C).
%
% Answer: QRout = [[q(0):[[cnot(q(2), q(0))], [not(q(0))]],
%                   q(1):q(1),
%                   q(2):q(2)],
%                  [q(0):q(0),
%                   q(1):q(1),
%                   q(2):[[tof(q(0), q(1), q(2))]]]]
%
%
% Robot Navigation
%
% Query:  query9(C).
%         q(0) is x, q(1) is y, q(2) is m
%
% Answer: C = [[q(0):q(0), q(1):[[cnot(q(2), q(1))], [not(q(1))]],q(2):q(2)],
%              [q(0):[[cnot(q(2), q(0))]], q(1):q(1), q(2):q(2)],
%              [q(0):[swap(q(1), q(0))], q(1):[swap(q(0),q(1))],q(2):q(2)]]
%
% Robot 2nd move
%
% Query: query19(C)
%        q(0) is x, q(1) is y, q(2) is m0, q(3) is m1
%
% Answer;
%   C = [[q(0):q(0),
%         q(1):q(1),
%         q(2):[[cnot(q(3), q(2))]],
%         q(3):q(3)],
%        [q(0):[[cnot(q(2), q(0))], [not(q(0))]],
%         q(1):q(1),
%         q(2):q(2),
%         q(3):q(3)],
%        [q(0):q(0),
%         q(1):[[cnot(q(2), q(1))], [not(q(1))]],
%         q(2):q(2),
%         q(3):q(3)]]
%
