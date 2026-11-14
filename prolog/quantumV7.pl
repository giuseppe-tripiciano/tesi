:- use_module(library(debug)).

% QOP/Gates
%
% QOP definitions
:- op(120, yfx, qAND).
:- op(150, xfy, [qXOR, qCZ, qCY, qCS]).
:- op(100, fy, [qH, qNOT, qRNOT, qZ, qY, qS, qT]).
%
% check QOP validity
q_operator(X) :- member(X, [qH, qNOT, qRNOT, qZ, qY, qS, qT, qXOR, qCZ, qCY, qCS, qSWAP, qAND, qCSWAP]).
%
% gate definitions
gate(qH,h,1).
gate(qNOT,not,1).
gate(qRNOT,rnot,1).
gate(qZ,pauli_Z,1).
gate(qY,pauli_Y,1).
gate(qS,phase,1).
gate(qT,pi_8,1).
gate(qXOR,cnot,2).
gate(qCZ,c_pauli_Z,2).
gate(qCY,c_pauli_Y,2).
gate(qCS,c_phase,2).
gate(qSWAP,swap,2).
gate(qAND,tof,3).
gate(qCSWAP,fredkin,3).


% Number sequence generator
% 
% init
:- asserta(qnn(0)).
%
:- asserta(cnn(0)).
%
% increment and index return
%
qbit_number(N) :-
    retract(qnn(N)),
    Np1 is N + 1,!,
    asserta(qnn(Np1)),!.
%
qvalue(N) :- var(N), qbit_number(N),!.
qvalue(_).
%
%
cbit_number(N) :-
    retract(cnn(N)),
    Np1 is N + 1,!,
    asserta(cnn(Np1)),!.
%
cvalue(N) :- var(N), cbit_number(N),!.
cvalue(_).
%
% reset 
reset_qbit_number :-
    retract(qnn(_)),
    asserta(qnn(0)).
%
reset_cbit_number :-
    retract(cnn(_)),
    asserta(cnn(0)).


% Expression translator
%
% base case
translate([q(N),q(N),[q(N)|_]], [q(N)]).
%
% 1-qbit gate case
translate([Formula,q(N),Qbits], [Layer_gate, Left]) :-
    Formula =.. [Op, LF], % unary formula decomposition
    last(Qbits,q(N)), % unify qbits list and target qbit
    q_operator(Op), % verify operator validity
    gate(Op,Gate,1), % get the 1-qbit gate corresponding to the operator
    Layer_gate =.. [Gate, q(N1)], % gate and qbit term construction
    translate([LF,q(N1),Qbits], Left). % sub-formula recursive call 
%
% Toffoli case
translate([LF qAND RF,q(N3),[q(N1), q(N2), q(N3)|_]], [tof(q(N1),q(N2),q(N3)), Left, Right]) :- !,
    translate([LF,q(N1),[q(N1)|_]], Left), % left sub-formula recursive call
    translate([RF,q(N2),[q(N2)|_]], Right). % right sub-formula recursive call        
%
% 2-qbit gate case
translate([Formula,q(N2),[q(N1),q(N2)|_]], [Layer_gate, Left, Right]) :-
    Formula =.. [Op, LF, RF], % binary formula decomposition
    q_operator(Op), % verify operator validity
    gate(Op,Gate,2), % get the 2-qbit gate corresponding to the operator
    translate([LF,q(N1),QbitsL], Left), % left sub-formula recursive call
    append(_,[q(N1)],QbitsL), % unify left qbits list and target qbit
    translate([RF,q(N2),QbitsR], Right), % right sub-formula recursive call 
    append(_,[q(N2)],QbitsR), % unify right qbits list and target qbit
    Layer_gate =.. [Gate, q(N1), q(N2)]. % gate and qbits term construction

% Expression normalization
%
% base case
normalize(q(N), q(N)) :- !.
%
% unary operator
normalize(Formula_in, Formula_out):- 
    Formula_in =.. [Op, Arg_in], 
    normalize(Arg_in, Arg_out),
    Formula_out =.. [Op, Arg_out].
%
% binary operator
normalize(Formula_in, Formula_out) :- 
    Formula_in =.. [Op, Arg1_in, Arg2_in],
    normalize(Arg1_in, Arg1_out), 
    normalize(Arg2_in, Arg2_out), 
    Formula_out =.. [Op, Arg1_out, Arg2_out].


% Circuit structure
%
% circuit tree representation (nested lists)
%
circuit_tree(Formula,Qbit,Circuit_tree) :- 
    normalize(Formula, Norm_formula), !,
    translate([Norm_formula,Qbit,_], Circuit_tree).
%
% log of non-trivial formula-to-tree translations (enable with "debug(circuit_tree)", disable with "nodebug(circuit_tree)")
circuit_tree_log(Formula,Qbit,Tree) :-
    (Qbit = q(0) -> (write('Non-trivial formula -> tree translations:'), nl, write('{')) ; true),
    (Formula \= q(_) -> format('~n Target:  ~w~n Formula: ~p~n Tree:    ~w~n', [Qbit, Formula, Tree]) ; true),
    ((qnn(N), N1 is N-1, Qbit = q(N1)) -> (write('}'), nl, nl) ; true).
%
% circuit layer representation (list of lists)
%
qcircuit(Formula,Qbit,Layers) :-
    circuit_tree(Formula,Qbit,Tree), 
    debug(circuit_tree, '~@', [circuit_tree_log(Formula,Qbit,Tree)]),
    layers(Tree, Layers).
%
% gates extraction
%
level_gates([],[]).
level_gates([[Gate|_]| Rest_trees],[Gate|Rest_gates]) :-
    level_gates(Rest_trees,Rest_gates).
%
% subtrees extraction
%
% base case
subtrees([], []).
%
% subtrees len < 3
subtrees([Subs | Rest_trees], Subtrees) :-  
    length(Subs,Subs_len), Subs_len < 3,
    Subs = [_|Rest_subs],
    subtrees(Rest_trees, Other_subs),   
    append(Rest_subs, Other_subs, Subtrees).
%
% subtrees len = 3
subtrees([Subs | Rest_trees], Subtrees) :- 
    length(Subs,Subs_len), Subs_len = 3,
    Subs = [_|[_|Rest_subs]],
    subtrees(Rest_trees, Other_subs),   
    append(Rest_subs, Other_subs, Subtrees). 
%
%
% layers construction
layers(Tree, Levels) :- all_layers([Tree], Levels).
%
% base case
all_layers([],[]).
%
% layers -> lists of gates applied at a specific circuit level 
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
%
make_cbits(0,[]).
make_cbits(N,[c(M):c(M)|RRest]) :-
    N>0,
    Nm1 is N-1,
    cbit_number(M),
    make_cbits(Nm1,RRest).


% Fill_Register with expressions
% 
% base case
fill_register(Reg,[],Reg).
%
% base case 2
fill_register([],_,[]).
%
% fill if register bit == expression bit 
fill_register([Bit:_|Rin],[Bit:Exp|Rest],[Bit:Exp|Rout]) :-
    member(Bit,[q(_),c(_)]), !, % check bit type
    fill_register(Rin,Rest,Rout).
%
% continue if register bit =/= expression bit
fill_register([BitK:Val|Rin],[Bit:Exp|Rest],[BitK:Val|Rout]) :-
    BitK \= Bit,
    fill_register(Rin,[Bit:Exp|Rest],Rout).


% QOP/Exp special cases
%
% 2-qbit QOP 
apply_operator(QOP2,[Qbit1,Qbit2],RegIn,RegOut) :-
    q_operator(QOP2),
    gate(QOP2,Gate,2),
    make_exps(Gate,[Qbit1:ExP1,Qbit2:Exp2]),
    fill_register(RegIn,[Qbit1:ExP1,Qbit2:Exp2],RegOut).
%
% 3-qbit QOP
apply_operator(QOP3,[Qbit1,Qbit2,Qbit3],RegIn,RegOut) :-
    q_operator(QOP3),
    gate(QOP3,Gate,3),
    make_exps(Gate,[Qbit1:Exp1,Qbit2:Exp2,Qbit3:Exp3]),
    fill_register(RegIn,[Qbit1:Exp1,Qbit2:Exp2,Qbit3:Exp3],RegOut).
%
% measurement operator
%
% single measurement
apply_operator(measurement,[q(N1),c(N2)],QRegister,CRegister,RegOut) :- !,
    append(QRegister,CRegister,RegIn),
    make_exps(measurement,[q(N1):Exp1,c(N2):Exp2]),
    fill_register(RegIn,[q(N1):Exp1,c(N2):Exp2],RegOut).
%
% list measurement
apply_operator(measurement,[Qbits,Cbits],QRegister,CRegister,RegOut) :-
    append(QRegister,CRegister,RegIn),
    make_exps(measurement,[Qbits,Cbits],Exp),
    fill_register(RegIn,Exp,RegOut).
% 
%
% SWAP exp
make_exps(swap,[Qbit1:Qbit1,Qbit2:[swap(Qbit1,Qbit2)]]).
%
% Fredkin exp
make_exps(fredkin,[Qbit1:Qbit1,Qbit2:Qbit2,Qbit3:[cswap(Qbit1,Qbit2,Qbit3)]]).
%
% measurement exp
%
% single measurement
make_exps(measurement,[Qbit:[measured(Cbit,Qbit)],Cbit:[measure(Qbit,Cbit)]]).
%
% list measurement
make_exps(measurement,[Qbits,Cbits],Exp) :- 
    maplist(measured_exp,Qbits,Cbits,QExp),
    maplist(measure_exp,Qbits,Cbits,CExp),
    append(QExp,CExp,Exp).   
%
% measured mapping
measured_exp(Qbit,Cbit,Qbit:measured(Cbit,Qbit)).
%
% measure mapping
measure_exp(Qbit,Cbit,Cbit:measure(Qbit,Cbit)).


% Utility exps
%
% superpose a list of qbits
superpose([],[]) :- !.
superpose([q(N)|RestIn], [q(N):qH q(N)|RestOut]) :-
    superpose(RestIn, RestOut).
%
% negate a list of qbits
negate([],[]) :- !.
negate([q(N)|RestIn], [q(N):qNOT q(N)|RestOut]) :-
    negate(RestIn, RestOut).
%
% bitwise qXOR 
bw_qXOR([], [], []) :- !.
bw_qXOR([Qbit1|QRest1], [Qbit2|QRest2], [Qbit2: Qbit1 qXOR Qbit2 | RestOut]) :-
    bw_qXOR(QRest1, QRest2, RestOut).
%
% qXOR 1:n
qXOR_1n(_,[],[]) :- !.
qXOR_1n(q(C),[q(T)|RestIn],[q(T): q(C) qXOR q(T)|RestOut]) :-
    qXOR_1n(q(C),RestIn,RestOut).
%
% qXOR n:1
qXOR_n1([X],X) :- !.
qXOR_n1([X|RestIn], X qXOR RestOut) :-
    qXOR_n1(RestIn, RestOut).


% return the list of bits in a specified index interval [N1,N2) with N1=0 as default
qrange(N1,N2,Range) :- R is N2-1, qidx_check(R), findall(q(N),between(N1,R,N),Range).
qrange(N2,Range) :- R is N2-1, qidx_check(R), findall(q(N),between(0,R,N),Range).
%
crange(N1,N2,Range) :- R is N2-1, cidx_check(R), findall(c(N),between(N1,R,N),Range).
crange(N2,Range) :- R is N2-1, cidx_check(R), findall(c(N),between(0,R,N),Range).

% check bit existence
qidx_check(QIDX) :- qnn(MAX), QIDX < MAX.
%
cidx_check(CIDX) :- cnn(MAX), CIDX < MAX.


% Transform QR1 -> QR2
%
% compile the expressions in QR1
transform([],[]).
transform([q(K):Exp|Rin],[q(K): Circ|Rout]) :- !,
    qcircuit(Exp,q(K),Circ), transform(Rin,Rout).


% Build a circuit
%  
% build_circuit(Register,Exp/Op,Circuit)
%
% standard case
build_circuit(QRegister,exp(Exp),[FCircuit]) :-
    fill_register(QRegister,Exp,QRfilled),
    transform(QRfilled,Circuit),
    filter(Circuit,FCircuit).
%
% or case
% De Morgan law -> Q1 OR Q2 = qNOT (qNOT Q1 qAND qNOT Q2)
build_circuit(QRegister,or,[q(N1),q(N2),q(N3)],NCircuit) :- !,
    % compute control negation
    build_circuit(QRegister,exp([q(N1): qNOT q(N1), q(N2): qNOT q(N2)]),[QRout]),

    % target action and negation
    complete_circuit(QRegister,[QRout],exp([q(N3): qNOT (q(N1) qAND q(N2))]),NCircuit1),
    
    % uncompute control negation
    reverse(QRout,Inv_QRout),
    append(NCircuit1,[Inv_QRout],NCircuit).
%
% QOP case
build_circuit(QRegister,operator(QOP),Qbits,[Circuit]) :-
    apply_operator(QOP,Qbits,QRegister,Circuit).
%
% ghz case
build_circuit(QRegister,ghz,Qbits,NCircuit) :-
    % query validation
    length(Qbits,Q_len), Q_len > 1,

    % entanglement
    append([q(C)],TQbits,Qbits),
    build_circuit(QRegister,exp([q(C): qH q(C)]),QRout),
    qXOR_1n(q(C),TQbits,GHZ),
    complete_circuit(QRegister,QRout,exp(GHZ),NCircuit).
%
% parity case
build_circuit(QRegister,parity,CQbits,[q(A),q(T)],NCircuit) :-
    % query validation
    length(CQbits,CQ_len), CQ_len > 1,

    % compute
    reverse(CQbits,Inv_CQbits),
    append(Inv_CQbits,[q(A)],Inv_CAQbits),
    qXOR_n1(Inv_CAQbits,Parity),
    build_circuit(QRegister,exp([q(A): Parity]),PC_QRout),

    % target action
    complete_circuit(QRegister,PC_QRout,exp([q(T): q(A) qXOR q(T)]),NCircuit1),

    % uncompute
    append(CQbits,[q(A)],CAQbits),
    qXOR_n1(CAQbits,Inv_Parity),
    complete_circuit(QRegister,NCircuit1,exp([q(A): Inv_Parity]),NCircuit).
%
% n-or case 
% De Morgan law -> Q1 OR Q2...OR Qn = qNOT (qNOT Q1 qAND qNOT Q2...qAND qNOT Qn)
build_circuit(QRegister,n-or,CQbits,ATQbits,NCircuit) :- 
    % compute control negation
    negate(CQbits,Neg),
    build_circuit(QRegister,exp(Neg),[QRout]), !,

    % n-tof - conj mode
    complete_circuit(QRegister,[QRout],n-tof,CQbits,ATQbits,conj,NCircuit1),

    % target negation
    last(ATQbits,q(T)),
    complete_circuit(QRegister,NCircuit1,exp([q(T): qNOT q(T)]),NCircuit2),

    % uncompute control negation
    reverse(QRout,Inv_QRout),
    append(NCircuit2,[Inv_QRout],NCircuit).
%
% n-tof default mode case
build_circuit(QRegister,n-tof,CQbits,ATQbits,NCircuit) :- build_circuit(QRegister,n-tof,CQbits,ATQbits,conj,NCircuit).
%
% incrementer case
build_circuit(QRegister,incr,q(C),[],q(T),NCircuit) :- !,
    build_circuit(QRegister,exp([q(T): q(C) qXOR q(T)]),NCircuit1),
    complete_circuit(QRegister,NCircuit1,exp([q(C): qNOT q(C)]),NCircuit). 
%
build_circuit(QRegister,incr,[q(C1),q(C2)],[],q(T),NCircuit) :- !,
    build_circuit(QRegister,exp([q(T): q(C1) qAND q(C2)]),NCircuit1),
    complete_circuit(QRegister,NCircuit1,incr,q(C1),_,q(C2),NCircuit).
%
build_circuit(QRegister,incr,CQbits,AQbits,q(T),NCircuit) :- 
    append(AQbits,[q(T)],ATQbits),
    build_circuit(QRegister,n-tof,CQbits,ATQbits,NCircuit1),
    append(CQRest,[q(T1)],CQbits),
    append(AQRest,[q(_)],AQbits),
    complete_circuit(QRegister,NCircuit1,incr,CQRest,AQRest,q(T1),NCircuit).
%
% decrementer case
build_circuit(QRegister,decr,CQbits,AQbits,TQbit,NCircuit) :-
    build_circuit(QRegister,incr,CQbits,AQbits,TQbit,NCircuit1),
    reverse(NCircuit1,NCircuit).
%
% n-tof case
build_circuit(_,n-tof,[q(_)],[],_,[]) :- !.
%
build_circuit(QRegister,n-tof,CQbits,ATQbits,Mode,NCircuit) :-
    % query validation
    length(CQbits,CQ_len), CQ_len > 1, length(ATQbits,ATQ_len), ATQ_len is CQ_len - 1,

    % compute first tof
    CQbits = [q(C1)|CQRest1],
    CQRest1 = [q(C2)|CQRest],
    ATQbits = [q(T)|_],
    build_circuit(QRegister,exp([q(T): q(C1) qAND q(C2)]),QRout),

    % n-tof
    complete_circuit(QRegister,[],QRout,n-tof,CQRest,ATQbits,Mode,NCircuit).


% Circuit structure cleaning
%
% base case
filter([],[]).
%
% identity case
filter([q(N):q(N)|Rest],[q(N):q(N)|FRest]) :- !,
    filter(Rest,FRest).
%
% remove redundant wrappers
filter([q(N):[[q(N)]]|Rest],[q(N):q(N)|FRest]) :- !,
    filter(Rest,FRest).
%
% remove first layer
filter([q(N):Circ|Rest],[q(N):FCirc|FRest]) :-
    reverse(Circ,[_|FCirc]),
    filter(Rest,FRest).


% Complete a circuit (add new ports at the end)
%   
% complete_circuit(Register,Previous,Exp/Op,New)
%
% standard case
complete_circuit(QRegister,PCircuit,exp(Exp),NCircuit) :-
    fill_register(QRegister,Exp,QRfilled),
    transform(QRfilled,Add_Circuit),
    filter(Add_Circuit,FAddCircuit),
    append(PCircuit,[FAddCircuit],NCircuit).
%
% or case
% De Morgan law -> Q1 OR Q2 = qNOT (qNOT Q1 qAND qNOT Q2)
complete_circuit(QRegister,PCircuit,or,[q(N1),q(N2),q(N3)],NCircuit) :- !,
    % compute control negation
    build_circuit(QRegister,exp([q(N1): qNOT q(N1), q(N2): qNOT q(N2)]),[QRout]),

    % target action and negation
    complete_circuit(QRegister,[QRout],exp([q(N3): qNOT (q(N1) qAND q(N2))]),NCircuit1),

    % uncompute control negation
    reverse(QRout,Inv_QRout),
    append(NCircuit1,[Inv_QRout],NCircuit2),

    % append to partital circuit
    append(PCircuit,NCircuit2,NCircuit).
%
% QOP case
complete_circuit(QRegister,PCircuit,operator(QOP),Qbits,NCircuit) :-
    apply_operator(QOP,Qbits,QRegister,QRout),
    append(PCircuit,[QRout],NCircuit).
%
% ghz case
complete_circuit(QRegister,PCircuit,ghz,Qbits,NCircuit) :-
    % query validation
    length(Qbits,Q_len), Q_len > 1,

    % entanglement
    append([q(C)],TQbits,Qbits),
    complete_circuit(QRegister,PCircuit,exp([q(C): qH q(C)]),NCircuit1),
    qXOR_1n(q(C),TQbits,GHZ),
    complete_circuit(QRegister,NCircuit1,exp(GHZ),NCircuit).
%
% parity case
complete_circuit(QRegister,PCircuit,parity,CQbits,[q(A),q(T)],NCircuit) :-
    % query validation
    length(CQbits,CQ_len), CQ_len > 1,

    % compute
    reverse(CQbits,Inv_CQbits),
    append(Inv_CQbits,[q(A)],Inv_CAQbits),
    qXOR_n1(Inv_CAQbits,Parity),
    complete_circuit(QRegister,PCircuit,exp([q(A): Parity]),NCircuit1),

    % target action
    complete_circuit(QRegister,NCircuit1,exp([q(T): q(A) qXOR q(T)]),NCircuit2),

    % uncompute
    append(CQbits,[q(A)],CAQbits),
    qXOR_n1(CAQbits,Inv_Parity),
    complete_circuit(QRegister,NCircuit2,exp([q(A): Inv_Parity]),NCircuit). 
%
% single measurement case
complete_circuit(QRegister,CRegister,PCircuit,measurement,[q(N1),c(N2)],NCircuit) :- !,
    apply_operator(measurement,[q(N1),c(N2)],QRegister,CRegister,OutCircuit),
    append(PCircuit,[OutCircuit],NCircuit).
%
% list measurement case
complete_circuit(QRegister,CRegister,PCircuit,measurement,[Qbits,Cbits],NCircuit) :-
    % query validation
    length(Qbits,Q_len), length(Cbits,C_len), Q_len is C_len, 

    % measurement
    apply_operator(measurement,[Qbits,Cbits],QRegister,CRegister,OutCircuit),
    append(PCircuit,[OutCircuit],NCircuit).
%
% n-or case
% De Morgan law -> Q1 OR Q2...OR Qn = qNOT (qNOT Q1 qAND qNOT Q2...qAND qNOT Qn)
complete_circuit(QRegister,PCircuit,n-or,CQbits,ATQbits,NCircuit) :-
    % compute control negation
    negate(CQbits,Neg),
    build_circuit(QRegister,exp(Neg),[QRout]), !,

    % n-tof - conj mode
    complete_circuit(QRegister,[QRout],n-tof,CQbits,ATQbits,conj,NCircuit1),

    % target negation
    last(ATQbits,q(T)),
    complete_circuit(QRegister,NCircuit1,exp([q(T): qNOT q(T)]),NCircuit2),

    % uncompute control negation
    reverse(QRout,Inv_QRout),
    append(NCircuit2,[Inv_QRout],NCircuit3),

    % append to partial circuit
    append(PCircuit,NCircuit3,NCircuit).
%
% n-tof default mode case
complete_circuit(QRegister,PCircuit,n-tof,CQbits,ATQbits,NCircuit) :- complete_circuit(QRegister,PCircuit,n-tof,CQbits,ATQbits,conj,NCircuit).
%
% incrementer case
%
complete_circuit(QRegister,PCircuit,incr,q(C),[],q(T),NCircuit) :- !,
    complete_circuit(QRegister,PCircuit,exp([q(T): q(C) qXOR q(T)]),NCircuit1),
    complete_circuit(QRegister,NCircuit1,exp([q(C): qNOT q(C)]),NCircuit). 
%
complete_circuit(QRegister,PCircuit,incr,[q(C1),q(C2)],[],q(T),NCircuit) :- !,
    complete_circuit(QRegister,PCircuit,exp([q(T): q(C1) qAND q(C2)]),NCircuit1),
    complete_circuit(QRegister,NCircuit1,incr,q(C1),_,q(C2),NCircuit).
%
complete_circuit(QRegister,PCircuit,incr,CQbits,AQbits,q(T),NCircuit) :- 
    append(AQbits,[q(T)],ATQbits),
    complete_circuit(QRegister,PCircuit,n-tof,CQbits,ATQbits,NCircuit1),
    append(CQRest,[q(T1)],CQbits),
    append(AQRest,[q(_)],AQbits),
    complete_circuit(QRegister,NCircuit1,incr,CQRest,AQRest,q(T1),NCircuit).
%
% decrementer case
complete_circuit(QRegister,PCircuit,decr,CQbits,AQbits,TQbit,NCircuit) :-
    build_circuit(QRegister,incr,CQbits,AQbits,TQbit,NCircuit1),
    reverse(NCircuit1,NCircuit2),
    append(PCircuit,NCircuit2,NCircuit).
%
% n-tof case
%
% n-tof init
complete_circuit(_,PCircuit,n-tof,[q(_)],[],_,PCircuit) :- !.
%
complete_circuit(QRegister,PCircuit,n-tof,CQbits,ATQbits,Mode,NCircuit) :-
    % query validation
    length(CQbits,CQ_len), CQ_len > 1, length(ATQbits,ATQ_len), ATQ_len is CQ_len - 1,

    % compute first tof
    CQbits = [q(C1)|CQRest1],
    CQRest1 = [q(C2)|CQRest],
    ATQbits = [q(T)|_],
    complete_circuit(QRegister,PCircuit,exp([q(T): q(C1) qAND q(C2)]),NCircuit1),

    % isolate n-tof subcircuit
    append(PCircuit,TOF_PCircuit,NCircuit1),

    % n-tof
    complete_circuit(QRegister,PCircuit,TOF_PCircuit,n-tof,CQRest,ATQbits,Mode,NCircuit).
%
% n-tof base - conj mode
complete_circuit(_,PCircuit,TOF_PCircuit,n-tof,[],_,conj,NCircuit) :- 
    % uncompute
    reverse(TOF_PCircuit,TOF_InvCircuit1),
    TOF_InvCircuit1 = [_|TOF_InvCircuit],

    % compose n-tof subcircuit
    append(TOF_PCircuit,TOF_InvCircuit,TOF_Circuit),

    % compose circuit
    append(PCircuit,TOF_Circuit,NCircuit).
%
% n-tof base - chain mode
complete_circuit(_,PCircuit,TOF_PCircuit,n-tof,[],_,chain,NCircuit) :-
    % compose circuit
    append(PCircuit,TOF_PCircuit,NCircuit).
%
% n-tof
complete_circuit(QRegister,PCircuit,TOF_PCircuit,n-tof,CQbits,ATQbits,Mode,TOF_NCircuit) :-
    % compute tof 
    CQbits = [q(C)|CQRest],
    ATQbits = [q(A)|ATQRest],
    ATQRest = [q(T)|_],
    complete_circuit(QRegister,TOF_PCircuit,exp([q(T): q(C) qAND q(A)]),TOF_NCircuit1),

    % n-tof
    complete_circuit(QRegister,PCircuit,TOF_NCircuit1,n-tof,CQRest,ATQRest,Mode,TOF_NCircuit).


% Output compression
%
% compress
%
compress([], []) :- !.
%
compress([[SubExp|SubRest] | Rest], [FSubRest|FRest]) :- !,
    compress([SubExp|SubRest], FSubRest),
    compress(Rest, FRest).
%
compress([q(N):q(N)|Rest],FRest) :- !,
    compress(Rest,FRest).
%
compress([q(N):X|Rest], [q(N):X|FRest]) :- 
    compress(Rest,FRest).


% Formula portray
%
% infix binary op case
portray(Formula) :- compound(Formula),Formula =.. [Op, Left, Right],current_op(_, Type, Op),member(Type, [xfx, xfy, yfx]),!,format('~p ~w ~p', [Left, Op, Right]).
%
% unary op case
portray(Formula) :- compound(Formula),Formula =.. [Op, Right],current_op(_, fy, Op),!,(Right \= q(_) -> (format('~w (~p)', [Op, Right])) ; format('~w ~p', [Op, Right])).
    

% unlimited console output
:- set_prolog_flag(answer_write_options, [max_depth(0), max_length(0)]).


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
    build_circuit(QRin,exp([q(0): qH q(0)]),QRout),
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
    complete_circuit(QRin,QRout,exp([q(2): q(0) qAND q(1)]),NC).

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

% n-tof query
%
query11(QRout) :-
    reset_qbit_number,
    make_qbits(7,QRin),
    qrange(4,CQbits),qrange(4,7,ATQbits), 
    build_circuit(QRin,n-tof,CQbits,ATQbits,QRout).

% or operator query
%
query12(QRout) :-
    reset_qbit_number,
    make_qbits(3,QRin),
    build_circuit(QRin,or,[q(0),q(1),q(2)],QRout).

% n-or query
%
query13(QRout) :-
    reset_qbit_number,
    make_qbits(7,QRin),
    qrange(4,CQbits),qrange(4,7,ATQbits),
    build_circuit(QRin,n-or,CQbits,ATQbits,QRout).

% parity query
%
query14(QRout) :-
    reset_qbit_number,
    make_qbits(6,QRin),
    qrange(4,CQbits),qrange(4,6,ATQbits),
    build_circuit(QRin,parity,CQbits,ATQbits,QRout).

% ghz + measurement query
%
query15(NC) :-
    reset_qbit_number,reset_cbit_number,
    make_qbits(4,QRin),make_cbits(4,CRin),
    qrange(4,Qbits),crange(4,Cbits),
    build_circuit(QRin,ghz,Qbits,QRout),
    complete_circuit(QRin,CRin,QRout,measurement,[Qbits,Cbits],NC).

% incrementer query
%
query16(QRout) :-
    reset_qbit_number,
    make_qbits(9,QRin),
    qrange(5,CQbits),qrange(6,9,AQbits),Overflow_Qbit = q(5),
    build_circuit(QRin,incr,CQbits,AQbits,Overflow_Qbit,QRout).

%


%
% Tests:
%
% Query:  query1(QR).
%
% Answer: QR = [[q(0):[[cnot(q(2), q(0))],[not(q(0))]],q(1):q(1),q(2):q(2)]]
%
%
% Query:  query2(QR).
%
% Answer: QR = [[q(0):[[cnot(q(2), q(0))], [not(q(0))]], q(1):q(1), q(2):q(2)],
%               [q(0):q(0), q(1):[[cnot(q(2), q(1))]], q(2):q(2)]]
%
%
% Query:  query3(QR).
%
% Answer: QR = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)]]
%
%
% Query:  query4(NC).
%
% Answer: NC = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)],
%               [q(0):q(0),
%                q(1):[cswap(q(0), q(2), q(1))],
%                q(2):[cswap(q(0), q(1), q(2))]]]
%
%
% Query:  query5(C).  -- Entanglement
%
% Answer: C = [[q(0):[[h(q(0))]], q(1):q(1)],
%              [q(0):q(0), q(1):[[cnot(q(0), q(1))]]],
%              [q(0):[measured(c(0), q(0))], q(1):q(1), c(0):[measure(q(0), c(0))], c(1):c(1)],
%              [q(0):q(0), q(1):[measured(c(1), q(1))], c(0):c(0),c(1):[measure(q(1), c(1))]]]
%
%
% Query:  query6(C).
%
% Answer: C = [[q(0):[[cnot(q(2), q(0))], [pi_8(q(0))]],q(1):q(1),q(2):q(2)]]
%
%
% Query:  query7(C).
%
% Answer: C = [[q(0):[swap(q(1), q(0))], q(1):[swap(q(0), q(1))], q(2):q(2)], [q(0):q(0), q(1):q(1), q(2):[c_phase(q(1), q(2))]]]
%
%
% Query:  query8(C).
%
% Answer: C = [[q(0):q(0),
%               q(1):q(1),
%               q(2):[[tof(q(0),q(1),q(2))]],
%               q(3):q(3),
%               q(4):q(4)],
%              [q(0):q(0),
%               q(1):q(1),
%               q(2):q(2),
%               q(3):q(3),
%               q(4):[[tof(q(0),q(1),q(4))],[tof(q(4),q(2),q(4))],[tof(q(4),q(3),q(4))]]]]
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
% Query:  query10(C).
%         q(0) is x, q(1) is y, q(2) is m0, q(3) is m1
%
% Answer: C = [[q(0):q(0),
%               q(1):q(1),
%               q(2):[[cnot(q(3), q(2))]],
%               q(3):q(3)],
%              [q(0):[[cnot(q(2), q(0))], [not(q(0))]],
%               q(1):q(1),
%               q(2):q(2),
%               q(3):q(3)],
%              [q(0):q(0),
%               q(1):[[cnot(q(2), q(1))], [not(q(1))]],
%               q(2):q(2),
%               q(3):q(3)]]
%


%
% Query:  query11(C).  -- n-tof
%
% Answer: C = [[q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[tof(q(0),q(1),q(4))]],q(5):q(5),q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):[[tof(q(2),q(4),q(5))]],q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):q(5),q(6):[[tof(q(3),q(5),q(6))]]],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):[[tof(q(2),q(4),q(5))]],q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[tof(q(0),q(1),q(4))]],q(5):q(5),q(6):q(6)]]
%
%
% Query:  query12(C).  -- qOR
%
% Answer: C = [[q(0):[[not(q(0))]],
%               q(1):[[not(q(1))]],
%               q(2):q(2)],
%              [q(0):q(0),
%               q(1):q(1),
%               q(2):[[tof(q(0),q(1),q(2))],[not(q(2))]]]]
%
%
% Query:  query13(C)  -- n-or
%
% Answer: C = [[q(0):[[not(q(0))]],q(1):[[not(q(1))]],q(2):[[not(q(2))]],q(3):[[not(q(3))]],q(4):q(4),q(5):q(5),q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[tof(q(0),q(1),q(4))]],q(5):q(5),q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):[[tof(q(2),q(4),q(5))]],q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):q(5),q(6):[[tof(q(3),q(5),q(6))]]],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):[[tof(q(2),q(4),q(5))]],q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[tof(q(0),q(1),q(4))]],q(5):q(5),q(6):q(6)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):q(5),q(6):[[not(q(6))]]]]
%
%
% Query:  query14(C)  -- parity
%
% Answer: C = [[q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[cnot(q(0),q(4))],[cnot(q(1),q(4))],[cnot(q(2),q(4))],[cnot(q(3),q(4))]],q(5):q(5)],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):q(4),q(5):[[cnot(q(4),q(5))]]],
%              [q(0):q(0),q(1):q(1),q(2):q(2),q(3):q(3),q(4):[[cnot(q(3),q(4))],[cnot(q(2),q(4))],[cnot(q(1),q(4))],[cnot(q(0),q(4))]],q(5):q(5)]]
%
%
% Query:  query15(C)  -- ghz + measurement
%
% Answer: C = [[q(0):[[h(q(0))]],q(1):q(1),q(2):q(2),q(3):q(3)],
%              [q(0):q(0),q(1):[[cnot(q(0),q(1))]],q(2):[[cnot(q(0),q(2))]],q(3):[[cnot(q(0),q(3))]]],
%              [q(0):measured(c(0),q(0)),q(1):measured(c(1),q(1)),q(2):measured(c(2),q(2)),q(3):measured(c(3),q(3)),c(0):measure(q(0),c(0)),c(1):measure(q(1),c(1)),c(2):measure(q(2),c(2)),c(3):measure(q(3),c(3))]]
%
%