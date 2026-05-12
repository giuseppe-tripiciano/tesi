:- ensure_loaded('quantumV6_3.pl').

%% CIRCUIT SIZING
%
% queen dim
queenDIM(N, QueenDIM) :-
    QueenDIM is integer(ceiling(log(N)/log(2))).
%
% state dim
stateDIM(N, QueenDIM, StateDIM) :- 
    StateDIM is N * QueenDIM.
%
% checks ancilla dim
checksDIM(N, ChecksDIM) :-
    ChecksDIM is (N*(N-1)/2).
%
% aux ancilla dim
auxDIM(ChecksDIM, AuxDIM) :-
    AuxDIM is ChecksDIM - 3.
%
% dim = 
% = state dim (N*QueenDIM) + bitwise qXOR dim (QueenDIM) + overflow dim (1) + checks dim (N*(N-1))/2) + aux dim (ChecksDIM-3) 
dim(StateDIM, QueenDIM, ChecksDIM, AuxDIM, DIM) :-
    DIM is StateDIM + QueenDIM + ChecksDIM + AuxDIM + 1.
%
% get dims
get_dims(N, QueenDIM, StateDIM, ChecksDIM, AuxDIM, DIM) :-
    queenDIM(N, QueenDIM),
    stateDIM(N, QueenDIM, StateDIM),
    checksDIM(N, ChecksDIM),
    auxDIM(ChecksDIM, AuxDIM),
    dim(StateDIM, QueenDIM, ChecksDIM, AuxDIM, DIM).



%% QUEENS SPLIT
%
queens_split([], _, []) :- !.
queens_split(State_Qbits, QueenDIM, [Queen | Rest]) :-
    length(Queen, QueenDIM),             
    append(Queen, State_Rest, State_Qbits), !,                            
    queens_split(State_Rest, QueenDIM, Rest).



%% MODULAR SUBCIRCUITS
%
% check subcircuits
check_subcircuit(QRin, CQbits, ATQbits, Check_SubCircuit, Inv_Check_SubCircuit) :-
    build_circuit(QRin, n-tof, CQbits, ATQbits, chain, Check_SubCircuit),
    reverse(Check_SubCircuit, Inv_Check_SubCircuit).
%
% offset subcircuits
incr_subcircuit(QRin, CQbits, AQbits, Overflow_Qbit, Incr_SubCircuit, Decr_SubCircuit) :-
    build_circuit(QRin, incr, CQbits, AQbits, Overflow_Qbit, Incr_SubCircuit),
    reverse(Incr_SubCircuit, Decr_SubCircuit).



%% INIT
%
init(N,

    % base args
    QRin, Queens, XOR_Qbits, Check_Qbits, Aux_Qbits,

    % column equality args  
    CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit,   

    % diagonal equality args                   
    DEQ_Incr_SubCircuit, DEQ_Decr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, 
    Overflow_Qbit, DEQ_Check_FQbit
    
    ) :-


    % circuit sizing
    get_dims(N, QueenDIM, StateDIM, ChecksDIM, AuxDIM, DIM),


    % base args
    %
    % qbits register
    reset_qbit_number, 
    make_qbits(DIM, QRin),
    %
    % queens
    qrange(0, StateDIM, State_Qbits), 
    queens_split(State_Qbits, QueenDIM, Queens),
    %
    % xor qbits
    Aux_start is StateDIM + QueenDIM, 
    qrange(StateDIM, Aux_start, XOR_Qbits), 
    %
    % aux qbits
    Aux_end is Aux_start + AuxDIM,
    qrange(Aux_start, Aux_end, Aux_Qbits),
    %
    % overflow qbit
    Overflow_Qbit = q(Aux_end),
    %
    % check qbits
    Checks_start is Aux_end + 1,
    Checks_end is Checks_start + ChecksDIM,
    qrange(Checks_start, Checks_end, Check_Qbits),


    % column equality args 
    %
    % xor qbits except last one
    XOR_end is Aux_start - 1,
    qrange(StateDIM, XOR_end, XOR_PQbits),
    %
    % ceq check subcircuit 
    CEQ_Check_Aux_end is Aux_start + QueenDIM - 2, qrange(Aux_start, CEQ_Check_Aux_end, CEQ_Check_Aux_Qbits), 
    check_subcircuit(QRin, XOR_PQbits, CEQ_Check_Aux_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit),
    %
    % ceq check last qbit and xor qbit
    (   QueenDIM > 2 ->

        % xor last qbit case
        XOR_FQbit = q(XOR_end),
        CEQ_Check_FQbit_idx is CEQ_Check_Aux_end - 1,
        CEQ_Check_FQbit = q(CEQ_Check_FQbit_idx)
        ;
        % xor first qbit case
        XOR_FQbit = q(StateDIM),
        CEQ_Check_FQbit = q(XOR_end)
        
    ),


    % diagonal equality args
    %
    % deq incr subcircuit
    DEQ_Incr_Aux_end is Aux_start + QueenDIM - 2, qrange(Aux_start, DEQ_Incr_Aux_end, DEQ_Incr_Aux_Qbits),
    incr_subcircuit(QRin, XOR_Qbits, DEQ_Incr_Aux_Qbits, Overflow_Qbit, DEQ_Incr_SubCircuit, DEQ_Decr_SubCircuit),
    %
    % deq check subcircuit
    DEQ_Check_Aux_end is Aux_start + QueenDIM - 1, qrange(Aux_start, DEQ_Check_Aux_end, DEQ_Check_Aux_Qbits),
    check_subcircuit(QRin, XOR_Qbits, DEQ_Check_Aux_Qbits, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit),
    %
    % deq check last qbit
    DEQ_Check_FQbit_idx is DEQ_Check_Aux_end - 1,
    DEQ_Check_FQbit = q(DEQ_Check_FQbit_idx).
    


%% COLUMN EQUALITY COMPUTE
%
col_eq_compute(_, CEQ_Circuit, [_], _, _, _, _, _, _, _, CEQ_Circuit) :- !.
%
col_eq_compute(QRin, CEQ_PCircuit, [Queen | Rest], XOR_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, Check_Qbits, CheckRest, CEQ_Circuit) :- 

    % queen fanout
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [Fanout_Circuit]),


    % column equality checks
    col_eq(QRin, [], Rest, XOR_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, CheckRest, CheckRest1, CEQ_Checks_PCircuit), 


    % checks circuit
    CEQ_Checks_PCircuit1 = [Fanout_Circuit | CEQ_Checks_PCircuit],
    reverse(Fanout_Circuit, Inv_Fanout_Circuit),
    append(CEQ_Checks_PCircuit1, [Inv_Fanout_Circuit], CEQ_Checks_Circuit),


    % partial circuit append
    append(CEQ_PCircuit, CEQ_Checks_Circuit, CEQ_PCircuit1),


    col_eq_compute(QRin, CEQ_PCircuit1, Rest, XOR_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, Check_Qbits, CheckRest1, CEQ_Circuit).
%
% 
col_eq(_, CEQ_PCircuit, [], _, _, _, _, _, PCheckRest, PCheckRest, CEQ_PCircuit) :- !.
%
col_eq(QRin, CEQ_PCircuit, [Queen | Rest], XOR_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, [Check_Qbit | PCheckRest], CheckRest, CEQ_Circuit) :- 

    % queens qXOR
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [XOR_Circuit]),


    % check compute
    CEQ_Check_Compute = [XOR_Circuit | CEQ_Check_SubCircuit],
    
    % check action
    build_circuit(QRin, exp([Check_Qbit: XOR_FQbit qAND CEQ_Check_FQbit]), [CEQ_Check_Action]),

    % check uncompute
    reverse(XOR_Circuit, Inv_XOR_Circuit),
    append(Inv_CEQ_Check_SubCircuit, [Inv_XOR_Circuit], CEQ_Check_Uncompute),


    % col eq circuit
    CEQ_Check_Action_Uncompute = [CEQ_Check_Action | CEQ_Check_Uncompute],
    append(CEQ_Check_Compute, CEQ_Check_Action_Uncompute, CEQ_Check_Circuit),    


    % partial circuit append
    append(CEQ_PCircuit, CEQ_Check_Circuit, CEQ_PCircuit1),


    col_eq(QRin, CEQ_PCircuit1, Rest, XOR_Qbits, CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, PCheckRest, CheckRest, CEQ_Circuit).



%% DIAGONAL EQUALITY COMPUTE
%
diag_eq_compute(_, DEQ_Circuit, [_], _, _, _, _, _, _, _, _, _, DEQ_Circuit) :- !.
%
diag_eq_compute(QRin, DEQ_PCircuit, [Queen | Rest], XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, CheckRest, DEQ_Circuit) :-  

    % queen fanout
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [Fanout_Circuit]),


    % diagonal equality checks
    diag_eq(QRin, [], Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, CheckRest, CheckRest1, [], DEQ_Checks_PCircuit),


    % checks circuit
    DEQ_Checks_PCircuit1 = [Fanout_Circuit | DEQ_Checks_PCircuit],
    reverse(Fanout_Circuit, Inv_Fanout_Circuit),
    append(DEQ_Checks_PCircuit1, [Inv_Fanout_Circuit], DEQ_Checks_Circuit),


    % partial circuit append
    append(DEQ_PCircuit, DEQ_Checks_Circuit, DEQ_PCircuit1),


    diag_eq_compute(QRin, DEQ_PCircuit1, Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, CheckRest1, DEQ_Circuit).
%
%
diag_eq(_, DEQ_PCircuit, [], _, _, _, _, _, _, _, PCheckRest, PCheckRest, Inv_DEQ_Ctr_Chain, DEQ_PCircuit1) :- !,

    % ctr uncompute chain append
    append(DEQ_PCircuit, Inv_DEQ_Ctr_Chain, DEQ_PCircuit1).
%
diag_eq(QRin, DEQ_PCircuit, [Queen | Rest], XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, [Check_Qbit | PCheckRest], CheckRest, Inv_DEQ_Ctr_PChain, DEQ_Circuit) :- 

    % queens qXOR
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [XOR_Circuit]),


    % check compute
    DEQ_Check_Compute = [XOR_Circuit | DEQ_Check_SubCircuit],

    % check action
    build_circuit(QRin, exp([Check_Qbit: Overflow_Qbit qAND DEQ_Check_FQbit]), [DEQ_Check_Action]),

    % check uncompute
    reverse(XOR_Circuit, Inv_XOR_Circuit),
    append(Inv_DEQ_Check_SubCircuit, [Inv_XOR_Circuit], DEQ_Check_Uncompute),


    % diag eq circuit
    DEQ_Check_Action_Uncompute = [DEQ_Check_Action | DEQ_Check_Uncompute],
    append(DEQ_Check_Compute, DEQ_Check_Action_Uncompute, DEQ_Check_Circuit),  
    append(DEQ_Ctr_SubCircuit, DEQ_Check_Circuit, DEQ_PCircuit1),


    % partial circuit append
    append(DEQ_PCircuit, DEQ_PCircuit1, DEQ_PCircuit2),


    % ctr uncompute chain
    append(Inv_DEQ_Ctr_PChain, Inv_DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_PChain1),


    diag_eq(QRin, DEQ_PCircuit2, Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, PCheckRest, CheckRest, Inv_DEQ_Ctr_PChain1, DEQ_Circuit).



%% TEST
%
test(QRin, Aux_Qbits, Check_Qbits, Test_Circuit) :-
    append(Check_PQbits, [Check_FQbit, Test_Qbit], Check_Qbits),
    reverse(Aux_Qbits, Test_Aux_Qbits),
    last(Test_Aux_Qbits, Test_Aux_FQbit),
    negate(Check_Qbits, Neg_Exp),
    build_circuit(QRin, exp(Neg_Exp), [NOT_SubCircuit]),
    reverse(NOT_SubCircuit, Inv_NOT_SubCircuit),
    check_subcircuit(QRin, Check_PQbits, Test_Aux_Qbits, Test_Check_SubCircuit, Inv_Test_Check_SubCircuit),
    build_circuit(QRin, exp([Test_Qbit: qH Test_Qbit]), [H_SubCircuit]),
    build_circuit(QRin, exp([Test_Qbit: Test_Aux_FQbit qAND Check_FQbit]), Test_SubCircuit),

    Test_SubCircuit1 = [NOT_SubCircuit | Test_Check_SubCircuit],
    Test_SubCircuit2 = [H_SubCircuit | Test_SubCircuit],
    append(Test_SubCircuit1, Test_SubCircuit2, Test_SubCircuit3),
    Test_SubCircuit4 = [H_SubCircuit | Inv_Test_Check_SubCircuit],
    append(Test_SubCircuit3, Test_SubCircuit4, Test_SubCircuit5),
    append(Test_SubCircuit5, [Inv_NOT_SubCircuit], Test_Circuit).



%% QUEENS PROBLEM
%
% queens problem: circuit components
queens_problem(N, CEQ_Compute_Circuit, DDEQ_Compute_Circuit, SDEQ_Compute_Circuit, Test_Circuit) :- 
    
    % init
    init(N,

        % base args
        QRin, Queens, XOR_Qbits, Check_Qbits, Aux_Qbits,
        
        % column equality args
        CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit,  

        % diagonal equality args
        DEQ_Incr_SubCircuit, DEQ_Decr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit,   
        Overflow_Qbit, DEQ_Check_FQbit

        ),                                                                                                               
   

    % column equality compute circuit
    col_eq_compute(
        QRin, [], Queens, XOR_Qbits, 
        CEQ_Check_SubCircuit, Inv_CEQ_Check_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, 
        Check_Qbits, Check_Qbits, CEQ_Compute_Circuit1
        ),
        %
        compress(CEQ_Compute_Circuit1, CEQ_Compute_Circuit),


    % diff diagonal equality compute circuit
    diag_eq_compute(
        QRin, [], Queens, XOR_Qbits, 
        DEQ_Incr_SubCircuit, DEQ_Decr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, 
        Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, Check_Qbits, DDEQ_Compute_Circuit1
        ), 
        %
        compress(DDEQ_Compute_Circuit1, DDEQ_Compute_Circuit),
   

    % sum diagonal equality compute circuit
    diag_eq_compute(
        QRin, [], Queens, XOR_Qbits, 
        DEQ_Decr_SubCircuit, DEQ_Incr_SubCircuit, DEQ_Check_SubCircuit, Inv_DEQ_Check_SubCircuit, 
        Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, Check_Qbits, SDEQ_Compute_Circuit1
        ),
        % circuit truncation 
        append(SDEQ_Compute_Circuit2, [_], SDEQ_Compute_Circuit1),
        append(SDEQ_Compute_Circuit3, DEQ_Incr_SubCircuit, SDEQ_Compute_Circuit2),
        append(SDEQ_Compute_Circuit4, [_], SDEQ_Compute_Circuit3),
        %
        compress(SDEQ_Compute_Circuit4, SDEQ_Compute_Circuit),


    % test circuit
    test(
        QRin, 
        Aux_Qbits,
        Check_Qbits, 
        Test_Circuit1
        ),
        %
        compress(Test_Circuit1, Test_Circuit).
%
%
% queens problem: compute and test circuits
queens_problem(N, Compute_Circuit, Test_Circuit) :-

    % circuit components
    queens_problem(N, CEQ_Compute_Circuit, DDEQ_Compute_Circuit, SDEQ_Compute_Circuit, Test_Circuit),

    % compute
    append(DDEQ_Compute_Circuit, SDEQ_Compute_Circuit, DEQ_Compute_Circuit),
    append(CEQ_Compute_Circuit, DEQ_Compute_Circuit, Compute_Circuit).
%
%
% queens problem: circuit
queens_problem(N, Circuit) :- 

    % compute and test circuits
    queens_problem(N, Compute_Circuit, Test_Circuit),
     

    % uncompute
    maplist(reverse, Compute_Circuit, Uncompute_Circuit1),
    reverse(Uncompute_Circuit1, Uncompute_Circuit),


    % circuit
    append(Compute_Circuit, Test_Circuit, Compute_Test_Circuit),
    append(Compute_Test_Circuit, Uncompute_Circuit, Circuit).



% QUEENS PROBLEM 4X4
% Circuit components
% 
%
% QUERY: queens_problem(4,CEQ,DDEQ,SDEQ,Test)
%
%
% ANSWER:
% 
%
% | COLUMN EQUALITY |
%
% CEQ = [
%        
%
%        [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],           % Q0 FANOUT
%
%
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           % Q0 qXOR Q1        %                                                                        
%        [q(14):[[tof(q(8),q(9),q(14))]]],                              % qAND reduction    % Q0 qEQ Q1                                                                
%        [q(9):[[cnot(q(3),q(9))]],q(8):[[cnot(q(2),q(8))]]],           % Q0 qXOR Q1        %                 
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           % Q0 qXOR Q2        %     
%        [q(15):[[tof(q(8),q(9),q(15))]]],                              % qAND reduction    % Q0 qEQ Q2
%        [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],           % Q0 qXOR Q2        %
%
%
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           % Q0 qXOR Q3        %
%        [q(16):[[tof(q(8),q(9),q(16))]]],                              % qAND reduction    % Q0 qEQ Q3
%        [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],           % Q0 qXOR Q3        %
%
%
%        [q(9):[[cnot(q(1),q(9))]],q(9):[[cnot(q(0),q(8))]]],           % Q0 FANOUT
%
%      
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           % Q1 FANOUT
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           % Q1 qXOR Q2        %
%        [q(17):[[tof(q(8),q(9),q(17))]]],                              % qAND reduction    % Q1 qEQ Q2
%        [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],           % Q1 qXOR Q2        %
%
%         
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           % Q1 qXOR Q3        %
%        [q(18):[[tof(q(8),q(9),q(18))]]],                              % qAND reduction    % Q1 qEQ Q3
%        [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],           % Q1 qXOR Q3        % 
%
%
%        [q(9):[[cnot(q(3),q(9))]],q(8):[[cnot(q(2),q(8))]]],           % Q1 FANOUT
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           % Q2 FANOUT
%
%
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           % Q2 qXOR Q3        %
%        [q(19):[[tof(q(8),q(9),q(19))]]],                              % qAND reduction    % Q2 qEQ Q3
%        [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],           % Q2 qXOR Q3        %
%
%
%        [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],           % Q2 FANOUT
%
%
%       ]
%
%
% \ DIFFERENCE DIAGONAL EQUALITY \
%
% DDEQ = [
%
%
%         [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],          % Q0 FANOUT
%
%
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          % (Q0 + 1) qXOR Q1  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(14):[[tof(q(13),q(10),q(14))]]],                           % qAND reduction    % (Q0 + 1) qEQ Q1
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(3),q(9))]],q(8):[[cnot(q(2),q(8))]]],          % (Q0 + 1) qXOR Q1  %
%
%
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          % (Q0 + 2) qXOR Q2  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(15):[[tof(q(13),q(10),q(15))]]],                           % qAND reduction    % (Q0 + 2) qEQ Q2
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],          % (Q0 + 2) qXOR Q2  %
%
%
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          % (Q0 + 3) qXOR Q3  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(16):[[tof(q(13),q(10),q(16))]]],                           % qAND reduction    % (Q0 + 3) qEQ Q3
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],          % (Q0 + 3) qXOR Q3  %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%
%
%         [q(9):[[cnot(q(1),q(9))]],q(8):[[cnot(q(0),q(8))]]],          % Q0 FANOUT
%
%
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          % Q1 FANOUT
%
% 
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%    
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          % (Q1 + 1) qXOR Q2  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(17):[[tof(q(13),q(10),q(17))]]],                           % qAND reduction    % (Q1 + 1) qEQ Q2
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],          % (Q1 + 1) qXOR Q2  %
%
%
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          % (Q1 + 2) qXOR Q3  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(18):[[tof(q(13),q(10),q(18))]]],                           % qAND reduction    % (Q1 + 2) qEQ Q3
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],          % (Q1 + 2) qXOR Q3  %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%   
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%
%
%         [q(9):[[cnot(q(3),q(9))]],q(8):[[cnot(q(2),q(8))]]],          % Q1 FANOUT
%
%
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          % Q2 FANOUT
%
%
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          % (Q2 + 1) qXOR Q3  %
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(19):[[tof(q(13),q(10),q(19))]]],                           % qAND reduction    % (Q2 + 1) qEQ Q3
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %                   %
%         [q(9):[[cnot(q(7),q(9))]],q(8):[[cnot(q(6),q(8))]]],          % (Q2 + 1) qXOR Q3  %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % - 1
%         [q(13):[[tof(q(8),q(9),q(13))]]],                             %
%
%         [q(9):[[cnot(q(5),q(9))]],q(8):[[cnot(q(4),q(8))]]],          % Q2 FANOUT
%
%
%        ]
%
%
% / SUM DIAGONAL EQUALITY /
%
% SDEQ = [
%
%
%         ...
%         Dual of the previous one, obtained interchanging incrementer/decrementer roles
%         ...
%         Truncation 
%
%
%        ]   
%
% 
% * TEST *
%
% Test = [
%
%
%         [q(14):[[not(q(14))]],                                                %
%          q(15):[[not(q(15))]],                                                %
%          q(16):[[not(q(16))]],                                                %
%          q(17):[[not(q(17))]],                                                %
%          q(18):[[not(q(18))]],                                                %
%          q(19):[[not(q(19))]]],                                               %                                                               
%         [q(12):[[tof(q(14),q(15),q(12))]]],       %                           %                                                                    
%         [q(11):[[tof(q(16),q(12),q(11))]]],       %                           %                                                            
%         [q(10):[[tof(q(17),q(11),q(10))]]],       %                           %                                                            
%         [q(19):[[h(q(19))]]],                     %                           %                                                             
%         [q(19):[[tof(q(10),q(18),q(19))]]],       % Z-axis qAND reduction     % Z-axis qNOR reduction                                                                                   
%         [q(19):[[h(q(19))]]],                     %                           %                                                             
%         [q(10):[[tof(q(17),q(11),q(10))]]],       %                           %                                                             
%         [q(11):[[tof(q(16),q(12),q(11))]]],       %                           %                                                             
%         [q(12):[[tof(q(14),q(15),q(12))]]],       %                           %                                                             
%         [q(19):[[not(q(19))]],                                                %
%          q(18):[[not(q(18))]],                                                %
%          q(17):[[not(q(17))]],                                                %
%          q(16):[[not(q(16))]],                                                %
%          q(15):[[not(q(15))]],                                                %
%          q(14):[[not(q(14))]]]                                                %                                                           
%
%
%        ] 
%
%