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
    AuxDIM is ChecksDIM - 2.
%
% dim = 
% = state dim (N*QueenDIM) + bitwise qXOR dim (QueenDIM) + checks dim (N*(N-1))/2) + overflow dim (1)
%   + col test dim (1) + diag diff test dim (1) + diag sum test dim (1) + test dim (1) + aux dim (ChecksDIM-2) 
dim(StateDIM, QueenDIM, ChecksDIM, AuxDIM, DIM) :-
    DIM is StateDIM + QueenDIM + ChecksDIM + 5 + AuxDIM.
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
% nor subcircuit
nor_subcircuit(QRin, NOT_Qbits, CQbits, ATQbits, NOR_Subcircuit) :-
    negate(NOT_Qbits, Neg_Exp), 
    build_circuit(QRin, exp(Neg_Exp), NOT_SubCircuit),
    complete_circuit(QRin, NOT_SubCircuit, n-tof, CQbits, ATQbits, chain, NOR_Subcircuit).
%
% incrementer subcircuit
incr_subcircuit(QRin, CQbits, AQbits, Overflow_Qbit, Incr_SubCircuit) :-
    build_circuit(QRin, incr, CQbits, AQbits, Overflow_Qbit, Incr_SubCircuit).
%



%% INIT
%
init(N,

    % base args
    QRin, Queens, XOR_Qbits, Check_Qbits, 

    % column equality args  
    CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, CEQ_Test_Qbits,   

    % diagonal equality args                   
    DEQ_Incr_SubCircuit, Inv_DEQ_Incr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, 
    Overflow_Qbit, DEQ_Check_FQbit, DDEQ_Test_Qbits, SDEQ_Test_Qbits, 

    % test equality args  
    PTest_Qbits, Test_Qbits) :-


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
    Overflow_idx is StateDIM + QueenDIM, 
    qrange(StateDIM, Overflow_idx, XOR_Qbits), 
    %
    % check qbits
    Checks_start is Overflow_idx + 1,
    Checks_end is Checks_start + ChecksDIM,
    qrange(Checks_start, Checks_end, Check_Qbits),


    % column equality args 
    %
    % xor qbits except last one
    XOR_end is Overflow_idx - 1,
    qrange(StateDIM, XOR_end, XOR_PQbits),
    %
    % ceq check subcircuit 
    Aux_start is DIM - AuxDIM,
    CEQ_Check_Aux_end is Aux_start + QueenDIM - 2, qrange(Aux_start, CEQ_Check_Aux_end, CEQ_Check_Aux_Qbits), 
    nor_subcircuit(QRin, XOR_Qbits, XOR_PQbits, CEQ_Check_Aux_Qbits, CEQ_NOR_SubCircuit), reverse(CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit),
    %
    % ceq check last qbit and xor qbit
    CEQ_Check_FQbit_idx is CEQ_Check_Aux_end - 1,
    (   QueenDIM > 2 ->

        % xor last qbit case
        XOR_FQbit = q(XOR_end),
        CEQ_Check_FQbit = q(CEQ_Check_FQbit_idx)
        ;
        % xor first qbit case
        XOR_FQbit = q(StateDIM),
        CEQ_Check_FQbit = q(XOR_end)
        
    ),
    %
    % ceq test qbits
    qrange(Aux_start, DIM, Aux_Qbits),
    CEQ_Test_idx is Aux_start - 4, 
    CEQ_Test_TQbit = q(CEQ_Test_idx),
    append(Aux_Qbits, [CEQ_Test_TQbit], CEQ_Test_Qbits),


    % diagonal equality args
    %
    % overflow qbit
    Overflow_Qbit = q(Overflow_idx),
    %
    % deq incr subcircuit
    DEQ_Incr_Aux_end is Aux_start + QueenDIM - 2, qrange(Aux_start, DEQ_Incr_Aux_end, DEQ_Incr_Aux_Qbits),
    incr_subcircuit(QRin, XOR_Qbits, DEQ_Incr_Aux_Qbits, Overflow_Qbit, DEQ_Incr_SubCircuit), reverse(DEQ_Incr_SubCircuit, Inv_DEQ_Incr_SubCircuit),
    %
    % deq check subcircuit
    qrange(StateDIM, Checks_start, XOR_Overflow_Qbits),
    DEQ_Check_Aux_end is Aux_start + QueenDIM - 1, qrange(Aux_start, DEQ_Check_Aux_end, DEQ_Check_Aux_Qbits),
    nor_subcircuit(QRin, XOR_Overflow_Qbits, XOR_Qbits, DEQ_Check_Aux_Qbits, DEQ_NOR_SubCircuit), reverse(DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit),
    %
    % deq check last qbit
    DEQ_Check_FQbit_idx is DEQ_Check_Aux_end - 1,
    DEQ_Check_FQbit = q(DEQ_Check_FQbit_idx),
    %
    % diff deq test qbits
    DDEQ_Test_idx is Aux_start - 3, 
    DDEQ_Test_TQbit = q(DDEQ_Test_idx),
    append(Aux_Qbits, [DDEQ_Test_TQbit], DDEQ_Test_Qbits),
    %
    % sum deq test qbits
    SDEQ_Test_idx is Aux_start - 2, 
    SDEQ_Test_TQbit = q(SDEQ_Test_idx),
    append(Aux_Qbits, [SDEQ_Test_TQbit], SDEQ_Test_Qbits),


    % test args
    %
    % partial test qbits
    PTest_Qbits = [CEQ_Test_TQbit, DDEQ_Test_TQbit, SDEQ_Test_TQbit],
    %
    % test qbits
    Test_Aux_Qbit = q(Aux_start),
    Test_idx is Aux_start - 1,
    Test_TQbit = q(Test_idx),
    Test_Qbits = [Test_Aux_Qbit, Test_TQbit].



%% EQUALITY CONJUGATION OPERATOR
%
eq_conj(QRin, EQ_Compute, Check_Qbits, EQ_Test_Qbits, EQ_Circuit) :-

    % checks negation
    negate(Check_Qbits, Neg_Exp),
    build_circuit(QRin, exp(Neg_Exp), [Neg_Circuit]),


    % test
    build_circuit(QRin, n-tof, Check_Qbits, EQ_Test_Qbits, EQ_Test),

    % uncompute
    reverse(EQ_Compute, EQ_Uncompute),


    % equality circuit
    EQ_Neg_Test = [Neg_Circuit | EQ_Test],
    EQ_Neg_Uncompute = [Neg_Circuit | EQ_Uncompute],
    append(EQ_Neg_Test, EQ_Neg_Uncompute, EQ_Test_Uncompute),
    append(EQ_Compute, EQ_Test_Uncompute, EQ_Circuit).



%% COLUMN EQUALITY
%
% column equality conjugation
col_eq_conj(QRin, CEQ_Compute, [_], _, _, _, _, _, Check_Qbits, CEQ_Test_Qbits, _, CEQ_Circuit) :- !,

    % equality conjugation operator
    eq_conj(QRin, CEQ_Compute, Check_Qbits, CEQ_Test_Qbits, CEQ_Circuit).
%
col_eq_conj(QRin, CEQ_PCircuit, [Queen | Rest], XOR_Qbits, CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, Check_Qbits, CEQ_Test_Qbits, CheckRest, CEQ_Circuit) :- 

    % queen fanout
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [Fanout_Circuit]),


    % checks partial circuit
    col_eq(QRin, [], Rest, XOR_Qbits, CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, CheckRest, CheckRest1, CEQ_Checks_PCircuit), 


    % checks circuit
    CEQ_Checks_PCircuit1 = [Fanout_Circuit | CEQ_Checks_PCircuit],
    append(CEQ_Checks_PCircuit1, [Fanout_Circuit], CEQ_Checks_Circuit),

    % partial circuit append
    append(CEQ_PCircuit, CEQ_Checks_Circuit, CEQ_PCircuit1),

    col_eq_conj(QRin, CEQ_PCircuit1, Rest, XOR_Qbits, CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, Check_Qbits, CEQ_Test_Qbits, CheckRest1, CEQ_Circuit).
%
% column equality checks
col_eq(_, CEQ_PCircuit, [], _, _, _, _, _, PCheckRest, PCheckRest, CEQ_PCircuit) :- !.
%
col_eq(QRin, CEQ_PCircuit, [Queen | Rest], XOR_Qbits, CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, [Check_Qbit | PCheckRest], CheckRest, CEQ_Circuit) :- 

    % queens qXOR
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [XOR_Circuit]),


    % check compute
    CEQ_Check_Compute = [XOR_Circuit | CEQ_NOR_SubCircuit],
    
    % check action
    build_circuit(QRin, exp([Check_Qbit: XOR_FQbit qAND CEQ_Check_FQbit]), [CEQ_Check_Action]),

    % check uncompute
    append(Inv_CEQ_NOR_SubCircuit, [XOR_Circuit], CEQ_Check_Uncompute),


    % check circuit
    CEQ_Check_Action_Uncompute = [CEQ_Check_Action | CEQ_Check_Uncompute],
    append(CEQ_Check_Compute, CEQ_Check_Action_Uncompute, CEQ_Check_Circuit),    

    % partial circuit append
    append(CEQ_PCircuit, CEQ_Check_Circuit, CEQ_PCircuit1),

    col_eq(QRin, CEQ_PCircuit1, Rest, XOR_Qbits, CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, PCheckRest, CheckRest, CEQ_Circuit).



%% DIAGONAL EQUALITY
%
% diagonal equality conjugation
diag_eq_conj(QRin, DEQ_Compute, [_], _, _, _, _, _, _, _, Check_Qbits, DEQ_Test_Qbits, _, DEQ_Circuit) :- !,

    % equality conjugation operator
    eq_conj(QRin, DEQ_Compute, Check_Qbits, DEQ_Test_Qbits, DEQ_Circuit).
%
diag_eq_conj(QRin, DEQ_PCircuit, [Queen | Rest], XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, DEQ_Test_Qbits, CheckRest, DEQ_Circuit) :-  

    % queen fanout
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [Fanout_Circuit]),


    % checks partial circuit
    diag_eq(QRin, [], Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, CheckRest, CheckRest1, [], DEQ_Checks_PCircuit),


    % checks circuit
    DEQ_Checks_PCircuit1 = [Fanout_Circuit | DEQ_Checks_PCircuit],
    append(DEQ_Checks_PCircuit1, [Fanout_Circuit], DEQ_Checks_Circuit),

    % partial circuit append
    append(DEQ_PCircuit, DEQ_Checks_Circuit, DEQ_PCircuit1),

    diag_eq_conj(QRin, DEQ_PCircuit1, Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, DEQ_Test_Qbits, CheckRest1, DEQ_Circuit).
%
% diagonal equality checks
diag_eq(_, DEQ_PCircuit, [], _, _, _, _, _, _, _, PCheckRest, PCheckRest, Inv_DEQ_Ctr_Chain, DEQ_PCircuit1) :- !,

    % ctr uncompute chain append
    append(DEQ_PCircuit, Inv_DEQ_Ctr_Chain, DEQ_PCircuit1).
%
diag_eq(QRin, DEQ_PCircuit, [Queen | Rest], XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, [Check_Qbit | PCheckRest], CheckRest, Inv_DEQ_Ctr_PChain, DEQ_Circuit) :- 

    % queens qXOR
    bw_qXOR(Queen, XOR_Qbits, XOR_Exp),
    build_circuit(QRin, exp(XOR_Exp), [XOR_Circuit]),


    % check compute
    DEQ_Check_Compute = [XOR_Circuit | DEQ_NOR_SubCircuit],

    % check action
    build_circuit(QRin, exp([Check_Qbit: Overflow_Qbit qAND DEQ_Check_FQbit]), [DEQ_Check_Action]),

    % check uncompute
    append(Inv_DEQ_NOR_SubCircuit, [XOR_Circuit], DEQ_Check_Uncompute),


    % check circuit
    DEQ_Check_Action_Uncompute = [DEQ_Check_Action | DEQ_Check_Uncompute],
    append(DEQ_Check_Compute, DEQ_Check_Action_Uncompute, DEQ_Check_Circuit),  

    % ctr compute append
    append(DEQ_Ctr_SubCircuit, DEQ_Check_Circuit, DEQ_PCircuit1),

    % partial circuit append
    append(DEQ_PCircuit, DEQ_PCircuit1, DEQ_PCircuit2),

    % ctr uncompute chain
    append(Inv_DEQ_Ctr_PChain, Inv_DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_PChain1),

    diag_eq(QRin, DEQ_PCircuit2, Rest, XOR_Qbits, DEQ_Ctr_SubCircuit, Inv_DEQ_Ctr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, Overflow_Qbit, DEQ_Check_FQbit, PCheckRest, CheckRest, Inv_DEQ_Ctr_PChain1, DEQ_Circuit).



%% TEST
%
test(QRin, PTest_Qbits, Test_Qbits, Test_Circuit) :-
    build_circuit(QRin, n-tof, PTest_Qbits, Test_Qbits, Test_Circuit).



%% QUEENS PROBLEM
%
% queens problem: circuit components
queens_problem(N, CEQ_Circuit, DDEQ_Circuit, SDEQ_Circuit, Test_Circuit) :- 

    % init
    init(N,

        QRin, Queens, XOR_Qbits, Check_Qbits,  
               
        CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, CEQ_Test_Qbits,  

        DEQ_Incr_SubCircuit, Inv_DEQ_Incr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit,   
        Overflow_Qbit, DEQ_Check_FQbit, DDEQ_Test_Qbits, SDEQ_Test_Qbits,  

        PTest_Qbits, Test_Qbits  
        ),                                                                                                               
   
    % column equality circuit
    col_eq_conj(
        QRin, [], Queens, XOR_Qbits, 
        CEQ_NOR_SubCircuit, Inv_CEQ_NOR_SubCircuit, XOR_FQbit, CEQ_Check_FQbit, 
        Check_Qbits, CEQ_Test_Qbits, Check_Qbits, CEQ_Circuit1
        ), 
        compress(CEQ_Circuit1, CEQ_Circuit),

    % diff diagonal equality circuit
    diag_eq_conj(
        QRin, [], Queens, XOR_Qbits, 
        DEQ_Incr_SubCircuit, Inv_DEQ_Incr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, 
        Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, DDEQ_Test_Qbits, Check_Qbits, DDEQ_Circuit1
        ), 
        compress(DDEQ_Circuit1, DDEQ_Circuit),

    % sum diagonal equality circuit
    diag_eq_conj(
        QRin, [], Queens, XOR_Qbits, 
        Inv_DEQ_Incr_SubCircuit, DEQ_Incr_SubCircuit, DEQ_NOR_SubCircuit, Inv_DEQ_NOR_SubCircuit, 
        Overflow_Qbit, DEQ_Check_FQbit, Check_Qbits, SDEQ_Test_Qbits, Check_Qbits, SDEQ_Circuit1
        ), 
        compress(SDEQ_Circuit1, SDEQ_Circuit),

    % test circuit
    test(
        QRin, 
        PTest_Qbits, Test_Qbits, 
        Test_Circuit1
        ),
        compress(Test_Circuit1, Test_Circuit).
%
% queens problem: circuit
queens_problem(N, Circuit) :- 

    % circuit components
    queens_problem(N, CEQ_Circuit, DDEQ_Circuit, SDEQ_Circuit, Test_Circuit),
     

    % compute
    append(DDEQ_Circuit, SDEQ_Circuit, DEQ_Compute_Circuit),
    append(CEQ_Circuit, DEQ_Compute_Circuit, Compute_Circuit),

    % uncompute
    append(SDEQ_Circuit, DDEQ_Circuit, DEQ_Uncompute_Circuit),
    append(DEQ_Uncompute_Circuit, CEQ_Circuit, Uncompute_Circuit),


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
%        % CEQ COMPUTE %
%
%        [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],           % Q0 FANOUT
%
%
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           %                                                                         
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(11):[[tof(q(8),q(9),q(11))]]],                              % Q0 EQ Q1
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %                                                                     
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           %                  
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           %         
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(12):[[tof(q(8),q(9),q(12))]]],                              % Q0 EQ Q2
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       % 
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           %
%
%
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(13):[[tof(q(8),q(9),q(13))]]],                              % Q0 EQ Q3
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%
%
%        [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],           % Q0 FANOUT
%
%      
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           % Q1 FANOUT
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           %
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(14):[[tof(q(8),q(9),q(14))]]],                              % Q1 EQ Q2
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           %
%
%         
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(15):[[tof(q(8),q(9),q(15))]]],                              % Q1 EQ Q3
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%
%
%        [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],           % Q1 FANOUT
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           % Q2 FANOUT
%
%
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(16):[[tof(q(8),q(9),q(16))]]],                              % Q2 EQ Q3
%        [q(8):[[not(q(8))]],q(9):[[not(q(9))]]],                       %
%        [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],           %
%
%
%        [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],           % Q2 FANOUT
%
%
%        % CEQ TEST %
%
%        [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%        [q(21):[[tof(q(11),q(12),q(21))]]],
%        [q(22):[[tof(q(13),q(21),q(22))]]],
%        [q(23):[[tof(q(14),q(22),q(23))]]],
%        [q(24):[[tof(q(15),q(23),q(24))]]],
%        [q(17):[[tof(q(16),q(24),q(17))]]],               
%        [q(24):[[tof(q(15),q(23),q(24))]]],
%        [q(23):[[tof(q(14),q(22),q(23))]]],
%        [q(22):[[tof(q(13),q(21),q(22))]]],
%        [q(21):[[tof(q(11),q(12),q(21))]]],
%        [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%
%
%        % CEQ UNCOMPUTE %
%
%        ...
%        ...
%        ...
%       ]
%
%
% \ DIFFERENCE DIAGONAL EQUALITY \
%
% DDEQ = [
%         % DDEQ COMPUTE %
%
%         [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],          % Q0 FANOUT
%
%
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0 + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(11):[[tof(q(10),q(21),q(11))]]],                           % (Q0 + 1) EQ Q1
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          %
%
%
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0 + 2
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(12):[[tof(q(10),q(21),q(12))]]],                           % (Q0 + 2) EQ Q2
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          %
%
%
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0 + 3
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(13):[[tof(q(10),q(21),q(13))]]],                           % (Q0 + 3) EQ Q3    
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %   
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0 + 2
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0 + 1
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q0
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%
%
%         [q(8):[[cnot(q(0),q(8))]],q(9):[[cnot(q(1),q(9))]]],          % Q0 FANOUT
%
%
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          % Q1 FANOUT
%
% 
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q1 + 1
%         [q(8):[[not(q(8))]]],                                         %
%    
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(14):[[tof(q(10),q(21),q(14))]]],                           % (Q1 + 1) EQ Q2
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          %
%
%
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q1 + 2
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(15):[[tof(q(10),q(21),q(15))]]],                           % (Q1 + 2) EQ Q3
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q1 + 1
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%   
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q1
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%
%
%         [q(8):[[cnot(q(2),q(8))]],q(9):[[cnot(q(3),q(9))]]],          % Q1 FANOUT
%
%
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          % Q2 FANOUT
%
%
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q2 + 1
%         [q(8):[[not(q(8))]]],                                         %
%
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(16):[[tof(q(10),q(21),q(16))]]],                           % (Q2 + 1) EQ Q3
%         [q(21):[[tof(q(8),q(9),q(21))]]],                             %
%         [q(8):[[not(q(8))]],q(9):[[not(q(9))]],q(10):[[not(q(10))]]], %   
%         [q(8):[[cnot(q(6),q(8))]],q(9):[[cnot(q(7),q(9))]]],          %
%
%
%         [q(8):[[not(q(8))]]],                                         %
%         [q(9):[[cnot(q(8),q(9))]]],                                   % Q2
%         [q(10):[[tof(q(8),q(9),q(10))]]],                             %
%
%         [q(8):[[cnot(q(4),q(8))]],q(9):[[cnot(q(5),q(9))]]],          % Q2 FANOUT
%
%
%         % DDEQ TEST %
%
%         [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%         [q(21):[[tof(q(11),q(12),q(21))]]],
%         [q(22):[[tof(q(13),q(21),q(22))]]],
%         [q(23):[[tof(q(14),q(22),q(23))]]],
%         [q(24):[[tof(q(15),q(23),q(24))]]],
%         [q(18):[[tof(q(16),q(24),q(18))]]],               
%         [q(24):[[tof(q(15),q(23),q(24))]]],
%         [q(23):[[tof(q(14),q(22),q(23))]]],
%         [q(22):[[tof(q(13),q(21),q(22))]]],
%         [q(21):[[tof(q(11),q(12),q(21))]]],
%         [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%
%
%         % DDEQ UNCOMPUTE %
%
%         ...
%         ...
%         ...
%        ]
%
%
% / SUM DIAGONAL EQUALITY /
%
% SDEQ = [
%         % SDEQ COMPUTE %
%
%         ...
%         (Dual of the previous one, obtained interchanging incrementer/decrementer roles)
%         ...
%
%
%         % SDEQ TEST %
%
%         [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%         [q(21):[[tof(q(11),q(12),q(21))]]],
%         [q(22):[[tof(q(13),q(21),q(22))]]],
%         [q(23):[[tof(q(14),q(22),q(23))]]],
%         [q(24):[[tof(q(15),q(23),q(24))]]],
%         [q(19):[[tof(q(16),q(24),q(19))]]],               
%         [q(24):[[tof(q(15),q(23),q(24))]]],
%         [q(23):[[tof(q(14),q(22),q(23))]]],
%         [q(22):[[tof(q(13),q(21),q(22))]]],
%         [q(21):[[tof(q(11),q(12),q(21))]]],
%         [q(11):[[not(q(11))]],q(12):[[not(q(12))]],q(13):[[not(q(13))]],q(14):[[not(q(14))]],q(15):[[not(q(15))]],q(16):[[not(q(16))]]],
%
%
%         % SDEQ UNCOMPUTE %
%
%         ...
%         ...
%         ...
%        ]   
%
% 
% * TEST *
%
% Test = [
%         [q(21):[[tof(q(17),q(18),q(21))]]],
%         [q(20):[[tof(q(19),q(21),q(20))]]],
%         [q(21):[[tof(q(17),q(18),q(21))]]]
%        ] 
%
%