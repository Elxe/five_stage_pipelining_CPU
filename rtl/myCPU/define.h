
/****** Op Code ******/
`define RTYPE	6'b000000
`define ADDI	6'b001000
`define ADDIU	6'b001001
`define SLTI	6'b001010
`define SLTIU	6'b001011
`define ANDI	6'b001100
`define LUI	    6'b001111
`define ORI	    6'b001101
`define XORI	6'b001110
`define BEQ	    6'b000100
`define BNE	    6'b000101

`define BGTZ	6'b000111
`define BLEZ	6'b000110
`define BZ	    6'b000001	// BGEZAL, BLTZAL
`define J	    6'b000010
`define JAL	    6'b000011
`define LB	    6'b100000
`define LBU	    6'b100100
`define LH	    6'b100001
`define LHU	    6'b100101
`define LW	    6'b100011
`define LWL	    6'b100010
`define LWR	    6'b100110
`define SB	    6'b101000
`define SH	    6'b101001
`define SW	    6'b101011
`define SWL	    6'b101010
`define SWR	    6'b101110
`define SPEC	6'b010000	// MFC0, MFT0

/****** Function Code ******/
`define	MOVZ	6'b001010
`define MOVN    6'b001011 
`define	ADD	    6'b100000 
`define ADDU	6'b100001
`define SUB	    6'b100010
`define SUBU	6'b100011
`define SLT	    6'b101010
`define SLTU	6'b101011
`define DIV	    6'b011010
`define DIVU	6'b011011
`define MULT	6'b011000
`define MULTU	6'b011001
`define AND	    6'b100100
`define NOR	    6'b100111
`define OR	    6'b100101
`define XOR	    6'b100110
`define SLLV	6'b000100
`define SLL	    6'b000000
`define SRAV	6'b000111
`define SRA	    6'b000011
`define SRLV	6'b000110
`define SRL	    6'b000010
`define JR	    6'b001000
`define JALR	6'b001001
`define MFHI	6'b010000
`define MFLO	6'b010010
`define MTHI	6'b010001
`define MTLO	6'b010011
`define BREAK	6'b001101
`define SYSCALL	6'b001100
`define ERET	6'b011000

//BLTZ code
`define BLTZ	5'b00000
`define BGEZAL	5'b10001
`define BLTZAL	5'b10000
`define BGEZ	6'b00001
//SPEC rs code
`define MFC0	5'b00000
`define MTC0	5'b00100

/****** Internal Excode ******/
`define LS132R_EX_INT          6'h00 //Interrupt
`define LS132R_EX_ADEL         6'h04 //Address Error (load or fetch)
`define LS132R_EX_ADES         6'h05 //Address Error (store)
`define LS132R_EX_IBE          6'h06 //Bus Error (instruction fetch)
`define LS132R_EX_DBE          6'h07 //Bus Error (load or store)
`define LS132R_EX_SYS          6'h08 //Syscall
`define LS132R_EX_BP           6'h09 //Breakpoint
`define LS132R_EX_RI           6'h0a //Reserved Instruction
`define LS132R_EX_CPU          6'h0b //Coprocessor Unusable
`define LS132R_EX_OV           6'h0c //Arithmatic Overflow
`define LS132R_EX_TRAP         6'h0d //Trap
`define LS132R_EX_FPE          6'h0f //Float Point Exception
`define LS132R_EX_WATCH        6'h17 //Reference to WatchHi/WatchLo Address
`define LS132R_EX_MCHECK       6'h18 //Machine Check
`define LS132R_EX_CACHEERR     6'h1e //Cache Error
`define LS132R_EX_NMI          6'h10 //NMI

`define LS132R_EX_DSS          6'h20 //Debug Sigle Step
`define LS132R_EX_DBP          6'h21 //Debug Breakpoint
`define LS132R_EX_DDBL         6'h22 //Debug Data Break Load
`define LS132R_EX_DDBS         6'h23 //Debug Data Break Store
`define LS132R_EX_DIB          6'h24 //Debug Instruction Break
`define LS132R_EX_DINT         6'h25 //Debug Interrupt
`define LS132R_EX_DDBLIMPR     6'h32 //Debug Data Break Load Imprecise
`define LS132R_EX_DDBSIMPR     6'h33 //Debug Data Break Store Imprecise

`define LS132R_EX_WAIT         6'h1f //internal exception for handling inst WAIT