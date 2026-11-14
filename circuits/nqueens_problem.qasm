OPENQASM 3.0;
include "stdgates.inc";
qubit[20] q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[14];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[15];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[16];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[17];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[18];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[19];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[14];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[15];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[16];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[17];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[18];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[19];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[14];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[15];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[16];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[17];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[18];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[19];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

x q[14];
x q[15];
x q[16];
x q[17];
x q[18];
x q[19];
barrier q;

ccx q[14], q[15], q[12];
barrier q;

ccx q[16], q[12], q[11];
barrier q;

ccx q[17], q[11], q[10];
barrier q;

h q[19];
barrier q;

ccx q[10], q[18], q[19];
barrier q;

h q[19];
barrier q;

ccx q[17], q[11], q[10];
barrier q;

ccx q[16], q[12], q[11];
barrier q;

ccx q[14], q[15], q[12];
barrier q;

x q[19];
x q[18];
x q[17];
x q[16];
x q[15];
x q[14];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[19];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[18];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[17];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[16];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[15];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[14];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[19];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[18];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[17];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[8], q[9];
barrier q;

x q[8];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[16];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[15];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

ccx q[13], q[10], q[14];
barrier q;

ccx q[8], q[9], q[10];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

x q[8];
barrier q;

cx q[8], q[9];
barrier q;

ccx q[8], q[9], q[13];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[19];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[18];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[17];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[0], q[8];
cx q[1], q[9];
barrier q;

cx q[6], q[8];
cx q[7], q[9];
barrier q;

ccx q[8], q[9], q[16];
barrier q;

cx q[7], q[9];
cx q[6], q[8];
barrier q;

cx q[4], q[8];
cx q[5], q[9];
barrier q;

ccx q[8], q[9], q[15];
barrier q;

cx q[5], q[9];
cx q[4], q[8];
barrier q;

cx q[2], q[8];
cx q[3], q[9];
barrier q;

ccx q[8], q[9], q[14];
barrier q;

cx q[3], q[9];
cx q[2], q[8];
barrier q;

cx q[1], q[9];
cx q[0], q[8];
barrier q;
