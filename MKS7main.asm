; Roland MKS-7 Main ROM
;
; NEC uPD7810 CPU w/ no mask ROM
; ROM size of 8K ($0000-$1FFF)
; (2764 type EPROM, 8Kb x 8)
;
;	HOW TO COMPILE (via Macro Assembler AS V1.42 by Alfred Arnold):
;		asw MKS7main.asm -w -cpu 7810
;		P2BIN MKS7main.p MKS7main.bin -r $0000-$1FFF
;
	relaxed on
	cpu 7810
;
; ##################
; # MKS-7 HARDWARE #
; ##################
;
; Ana2Dig:
;			0 - master tune						[input]
;			1 - bass detune						[input]
;			2 - dynamic sense					[input]
;			3 - not used
;			4 - not used
;			5 - not used 
;			6 - not used
;			7 - not used
;
; Port A:
;			0 - switch data read				[input]
;			1 - switch data read				[input]
;			2 - switch data read				[input]
;			3 - switch data read				[input]
;			4 - switch data read				[input]
;			5 - bass env						[output]
;			6 - sustain level select			[output]
;			7 - bass waveform select			[output]
;
;			BUTTON SWITCH MATRIX
;			
;			0 			1 			2 			3 					4
;			[3]			[6] 		[9] 		[Transpose] 		[Melody Select]
;			[2]			[5]			[8]			[0]					[Chord Select]
;			[1]			[4]			[7]			[MIDI Channel]		[Bass Select]
;			[Melody]	[Chord]		[Bass]		[Rhythm]			x
;
; Port B:
;			Display LED driver					[output]
;
;			LIGHTING MATRIX
;			0			1			2			3			4			5			6			7			
;			(e)			(d)			(c)			(dp)		(g)			(f)			(b)			(a)		[lower digit]
;			(e)			(d)			(c)			(dp)		(g)			(f)			(b)			(a)		[upper digit]	
;			Chord		Melody		Bass		Rhythm		X			X			X			X		[note on indicator]
;			Chord		Melody		Bass		X			X			X			X			X		[display select]
;			
; Port C:	0 - serial out to MODULE			[output]
;			1 - serial Rx MIDI					[input]
;			2 - bass gate						[output]
;			3 - bass S/H DMUX inhibit			[output]
;			4 - bass S/H DMUX channel select	[output]
;			5 - bass S/H DMUX channel select	[output]
;			6 - bass S/H DMUX channel select	[output]
;			7 - bass pitch clock				[output]	
;
; Port D:
;			Data Bus							[in/out]
;
; Port F:
;			addressing (latch, chip select)		[output]
;
;			11xxxxxx = display select LEDs
;			10xxxxxx = note on indicator LEDs
;			01xxxxxx = upper digit LEDs
;			00xxxxxx = lower digit LEDs
;
; --------------
; | MEMORY MAP |
; --------------
;
; $0000~$1FFF = MAIN PROGRAM ROM (IC43)
; $2800       = ?
; $3000       = ? some peripheral?
; $3FFF       = ?
; $FF00~$FFFF = WORKING REGISTER RAM
;
; #################################
; # WORKING REGISTERS (IN CPU RAM # ($FF00~$FFFF)
; #################################
;
; $FF00 = ? specifically initialized on startup
; $FF01 = ? specifically initialized on startup
; $FF02 = ? specifically initialized on startup
; $FF03 = ? specifically initialized on startup
; $FF04 = ?
; $FF05 = ?
; $FF06 = ?
; $FF07 = ?
; $FF08 = ?
; $FF09 = ?
; $FF0A = ?
; $FF0B = something bit-tested, possibly MIDI related
; $FF0C = ?
; $FF0D = ?
; $FF0E = current MIDI byte? or Status byte?
; $FF0F = SysEx message length?
; $FF10 = ? current index for something?
; $FF11 = ? pending index for something?
; $FF12 = starting address of some buffer?
; ..
; $FF40 = serial Tx current index?
; $FF41 = serial Tx pending index?
; $FF42 to $FF6F = serial Tx buffer area?
; ..
; $FF89 = LED state A?
; $FF8A = LED state B?
; $FF8B	= LED state C?
; $FF8C = LED state D?
; $FF8D = button read state A?
; $FF8E = button read state B?
; $FF8F = starting address of some buffer?
; ..
; $FFA0 = master tune value?
; $FFA1 = bass detune value?
; $FFA2 = dynamic sense value?
; ..
; $FFA8 = starting address of some buffer?
; ..
; $FFBA = starting address of some buffer?
; ..
; $FFCC = starting address of some buffer?
; ..
; $FFD1 = ? related to peripheral at $2800?
; $FFD2 = ?
; $FFD3 = ?
; $FFD4 = starting address of incoming SysEx buffer?
; ..
; $FFFE = ?
; $FFFF = ?
;
; #####################
; # BEGIN PROGRAM ROM #
; #####################
;
; # ORIGIN
;
	ORG	$0000					; definition for assembler to begin addressing @ $0000 (no mask ROM, so no special alignment needed)
;
L0000: JMP     L02CA			; jump to main initialization on power-up
L0003: NOP						; spacer byte     
L0004: EI      					; IRQ0 (NMI) -- enable maskable interrupts 
L0005: RETI						; return from interrupt
;
; # vector table has been abused -- officially, this should not be data
;    
L0006: DB $98
L0007: NOP
;
; vector table -- IRQ1 (INTT0/INTT1) -- LEDs refresh and button switch reading at 20ms intervals?
;
L0008: JMP     L0297
;
; vector table has been abused -- mini data table referenced @ L1130
;
;
; Note: This is "illegal" because this part of the vector table is supposed to handle IRQ2 (INT1/INT2)
;       and IRQ3 (INTE0/INTE1)
;
L000B:
	DB $02,$03,$04,$05,$00,$06,$07,$08
	DB $09,$0A,$0B,$0C,$0D,$0E,$0F,$01
;
;
;
L001B: NOP
L001C: NOP
L001D: EXA     
L001E: EXX     
L001F: NOP
;
; vector table -- IRQ4 (INTEIN/INTAD)
;
L0020: EI      
L0021: RETI
;
; vector table has been abused -- mini data table referenced @ L094D (SysEx related?)
;
L0022:
	DB $FE,$FD,$FB,$F7
;
; # vector table -- IRQ4 (INTEIN/INTAD)
;
L0026: NOP     
L0027: NOP
;
; # vector table -- IRQ5 (INTSR/INTST)
;
L0028: EXA     
L0029: EXX     
L002A: OFFI    MKH,$04
L002D: JR      L0033			; otherwise
L002E: SKIT    FSR
L0030: JMP     L027C			; otherwise transmit info to MODULE
L0033: SKNIT   ER
L0035: JRE     L009D			; otherwise do something with MIDI Rx
L0037: ORIW    $A5,$50			; $FFA5
L003A: MOV     A,RXB			; receive MIDI
L003C: ONI     A,$80
L003E: JRE     L00D1			; otherwise MIDI Rx related
L0040: LTI     A,$F0
L0042: JRE     L00AC			; otherwise MIDI Rx related
L0044: ANIW    $87,$3F			; $FF87
L0047: MOV     E,A
L0048: ANI     A,$F0
L004A: EQI     A,$A0
L004C: NEI     A,$D0
L004E: JRE     L009F
L0050: MOV     B,A
L0051: MOV     A,E
L0052: ANI     A,$0F
L0054: MVI     C,$00
L0056: OFFIW   $0B,$10			; $FF0B
L0059: JR      L0061			; otherwise
L005A: EQAW    $00				; $FF00
L005D: JR      L0061			; otherwise
L005E: ORI     C,$01
L0061: EQAW    $01				; $FF01
L0064: JR      L0068			; otherwise
L0065: ORI     C,$02
L0068: EQAW    $02				; $FF02
L006B: JR      L006F			; otherwise
L006C: ORI     C,$04
L006F: EQAW    $03				; $FF03
L0072: JR      L007A			; otherwise
L0073: EQI     B,$90
L0076: JR      L007A			; otherwise
L0077: ORI     C,$08
L007A: MOV     A,C
L007B: ORA     A,B
L007D: STAW    $0E				; $FF0E
L007F: OFFI    C,$07
L0082: JR      L0087			; otherwise
L0083: ONI     A,$08
L0085: JR      L009F			; otherwise
L0086: JR      L0090
;
;
;
L0087: LTI     A,$A0
L0089: JR      L0090			; otherwise
L008A: MOV     C,A
L008B: ANIW    $0B,$BF			; $FF0B
L008E: CALF    L0A9F
; fall-through or jumped to
L0090: EQI     B,$C0
L0093: MVI     A,$01			; otherwise
L0095: MVI     A,$00
L0097: STAW    $0F				; $FF0F -- SysEx message length?
L0099: ORIW    $0B,$80			; $FF0B
L009C: JR      L00A2
;
; # MIDI Rx
;
L009D: MOV     A,RXB			; MIDI Rx, very likely
L009F: ANIW    $0B,$7F			; $FF0B -- something with MIDI related working register
; fall-through or shared routine to end interrupts
L00A2: EXA     
L00A3: EXX     
L00A4: EI      
L00A5: RETI
;
; # MIDI System Real-Time Handling
;    
L00A6: NEI     A,$FE			; skip next if MIDI code is not Active Sensing
L00A8: ANIW    $A5,$7F			; $FFA5 -- otherwise do something about Active Sensing
L00AB: JR      L00A2
;
; # MIDI Rx related
;
L00AC: LTI     A,$F8			; skip next if MIDI code is less than $F8 (ie not System Real-Time related)
L00AE: JR      L00A6			; otherwise handle System Real-Time related
L00AF: EQI     A,$F0			; skip next if MIDI SysEx Start code
L00B1: JR      L00BC			; otherwise handle SysEx Start
L00B2: ANIW    $87,$3F			; $FF87
L00B5: ORIW    $87,$80			; $FF87
L00B8: STAW    $0E				; $FF0E
L00BA: JRE     L0095
;
; # MIDI SysEx Start Handling
;
L00BC: EQI     A,$F7			; skip next if MIDI SysEx End code
L00BE: JR      L00CC			; otherwise process SysEx
L00BF: BIT     7,$87			; $FF87
L00C1: JR      L00CF			; otherwise
L00C2: BIT     5,$87			; $FF87
L00C4: JR      L00CC			; otherwise
L00C5: EQIW    $0F,$12			; $FF0F -- SysEx message length?
L00C8: JR      L00CC			; otherwise
L00C9: ORIW    $87,$10			; $FF87
; fall-through or jumped to for SysEx
L00CC: ANIW    $87,$3F			; clear bits 7 and 6 in $FF87 (reduce to 0~63)
L00CF: JRE     L009F
;
; # test high-bit of received MIDI?
;
L00D1: BIT     7,$0B			; $FF0B
L00D3: JRE     L00A2			; otherwise
L00D5: MOV     C,A
L00D6: OFFIW   $87,$80			; $FF87
L00D9: JMP     L01DC			; otherwise
L00DC: LTIW    $0E,$F0			; $FF0E -- skip next if less than $F0 (ie not System Exclusive)
L00DF: JRE     L009F			; otherwise assume SysEx, System Common, or System Real-Time
L00E1: DCRW    $0F				; $FF0F -- decrement SysEx message length?
L00E3: JR      L0103			; otherwise
L00E4: LTIW    $0E,$A0			; $FF0E -- check for Poly Aftertouch? [Ax]
L00E7: JRE     L010E			; otherwise
L00E9: MVIW    $0F,$01			; $FF0F -- SysEx message length?
L00EC: BIT     3,$0E			; $FF0E
L00EE: JR      L00F5			; otherwise
L00EF: NEI     C,$00
L00F2: JR      L00F5			; otherwise
L00F3: CALF    L0A7E
L00F5: ONIW    $0E,$07			; $FF0E
L00F8: JR      L00FF			; otherwise
L00F9: OFFIW   $0B,$40			; $FF0B
L00FC: JR      L00FF			; otherwise
L00FD: CALF    L0A9F
L00FF: EXA     
L0100: EXX     
L0101: EI      
L0102: RETI
;
;
;    
L0103: STAW    $0D				; $FF0D
L0105: LTIW    $0E,$A0			; $FF0E
L0108: JR      L00FF			; otherwise
L0109: ONIW    $0E,$07			; $FF0E
L010C: JR      L00FF			; otherwise
L010D: JR      L00F9
;
; # handle Poly Aftertouch or some other SysEx?
;
L010E: LTIW    $0E,$C0			; skip next if $FF0E is less then $C0
L0111: JRE     L0194			; otherwise potentially a Program Change [Cx]?
L0113: LDAW    $0D				; $FF0D
L0115: EQI     A,$01
L0117: JR      L0130			; otherwise
L0118: MOV     A,C
L0119: ORI     A,$80
L011B: BIT     0,$0E			; $FF0E
L011D: JR      L0123			; otherwise
L011E: BIT     2,$84			; $FF84
L0120: JR      L0123			; otherwise
L0121: STAW    $05				; $FF05
L0123: BIT     1,$0E			; $FF0E
L0125: JR      L012B			; otherwise
L0126: BIT     2,$83			; $FF83
L0128: JR      L012B			; otherwise
L0129: STAW    $08				; $FF08
L012B: MVIW    $0F,$01			; $FF0F -- SysEx message length?
L012E: JRE     L00FF
;
;
;
L0130: EQI     A,$40
L0132: JRE     L0156			; otherwise
L0134: LDAW    $0E				; $FF0E
L0136: ANI     A,$03
L0138: BIT     1,$83
L013A: ANI     A,$				; otherwise
L013C: BIT     1,$84
L013E: ANI     A,$02			; otherwise
L0140: ONI     A,$03
L0142: JR      L012B			; otherwise
L0143: EQI     C,$00
L0146: JR      L014E			; otherwise
L0147: ORI     A,$D0
L0149: MOV     C,A
L014A: CALF    L0A9F
L014C: JRE     L012B
;
;
;
L014E: EQI     C,$7F
L0151: JRE     L012B			; otherwise
L0153: ORI     A,$08
L0155: JR      L0147			; otherwise
L0156: NEI     A,$79
L0158: JR      L0171			; otherwise
L0159: GTI     A,$7A
L015B: JR      L016F			; otherwise
L015C: EQI     A,$7E
L015E: JR      L0163			; otherwise
L015F: ONI     C,$F0
L0162: JR      L0167			; otherwise
L0163: EQI     C,$00
L0166: JR      L016F			; otherwise
L0167: LDAW    $0E				; $FF0E
L0169: ONI     A,$07
L016B: JR      L016F			; otherwise
L016C: MOV     C,A
L016D: CALF    L0A9F
L016F: JRE     L012B
;
;
;
L0171: BIT     1,$0E
L0173: JR      L016F			; otherwise
L0174: EQI     C,$00
L0177: JR      L0181			; otherwise
L0178: BIT     4,$0B
L017A: JR      L016F			; otherwise
L017B: MVI     C,$C1
L017D: ANIW    $0B,$EF			; $FF0B
L0180: JR      L018E
;
;
;
L0181: EQI     C,$7F
L0184: JR      L016F			; otherwise
L0185: OFFIW   $0B,$10			; $FF0B
L0188: JR      L017A			; otherwise
L0189: MVI     C,$C0
L018B: ORIW    $0B,$10			; $FF0B
L018E: CALF    L0F79
L0190: CALF    L0F83
L0192: JRE     L016D
;
; # something SysEx?
;
L0194: LTIW    $0E,$E0			; skip next if $FF0E is less than $E0
L0197: JRE     L01C0			; otherwise potentially handle Pitch Wheel [Ex] ?
L0199: OFFIW   $93,$04			; $FF93
L019C: JR      L01BB			; otherwise
L019D: LTI     A,$64
L019F: SUI     A,$64			; otherwise
L01A1: ORI     A,$80
L01A3: BIT     0,$0E
L01A5: JR      L01AB			; otherwise
L01A6: BIT     0,$84
L01A8: JR      L01AB			; otherwise
L01A9: STAW    $06				; $FF06
L01AB: BIT     1,$0E
L01AD: JR      L01B3			; otherwise
L01AE: BIT     0,$83
L01B0: JR      L01B3			; otherwise
L01B1: STAW    $09				; $FF09
L01B3: BIT     2,$0E
L01B5: JR      L01BB			; otherwise
L01B6: BIT     0,$85
L01B8: JR      L01BB			; otherwise
L01B9: STAW    $0A				; $FF0A
L01BB: MVIW    $0F,$00			; $FF0F -- SysEx message length?
L01BE: JRE     L012E
;
; # handle SysEx pitch wheel messages?
;
L01C0: MOV     A,C
L01C1: MOV     EAH,A
L01C2: LDAW    $0D				; $FF0D
L01C4: SLL     A
L01C6: MOV     EAL,A
L01C7: DSLL    EA
L01C9: MOV     A,EAH
L01CA: BIT     0,$0E			; $FF0E
L01CC: JR      L01D2			; otherwise
L01CD: BIT     2,$84			; $FF84
L01CF: JR      L01D2			; otherwise
L01D0: STAW    $04				; $FF04
L01D2: BIT     1,$0E			; $FF0E
L01D4: JR      L01DA			; otherwise
L01D5: BIT     2,$83			; $FF83
L01D7: JR      L01DA			; otherwise
L01D8: STAW    $07				; $FF07
L01DA: JRE     L016F
;
;
;
L01DC: BIT     6,$87			; $FF87
L01DE: JRE     L0211			; otherwise
L01E0: BIT     5,$87			; $FF87
L01E2: JR      L0200			; otherwise
L01E3: LDAW    $0F				; $FF0F -- load SysEx message length?
L01E5: MOV     B,A
L01E6: MOV     A,C
L01E7: LXI     H,$FFD4			; buffer?
L01EA: STAX    H+B
L01EB: INRW    $0F				; $FF0F -- SysEx message length?
L01ED: NOP 						; negate potential skip    
L01EE: BIT     5,$87
L01F0: JR      L01F8			; otherwise
L01F1: EQIW    $0F,$12			; $FF0F -- SysEx message length?
L01F4: JR      L01F8			; otherwise
L01F5: ANIW    $0B,$7F			; $FF0B
L01F8: EXA     
L01F9: EXX     
L01FA: EI      
L01FB: RETI
;
; # do something with a working register and then abort SysEx?
;   
L01FC: ANIW    $87,$3F			; $FF87
L01FF: JR      L01F8			; jump to shared routine
;
;
;
L0200: BIT     0,$0F
L0202: JR      L020D			; otherwise
L0203: LDAW    $0D				; $FF0D
L0205: LTI     A,$12
L0207: JR      L020F			; otherwise
L0208: ORI     C,$80
L020B: JRE     L01E5
;
;
;
L020D: STAW    $0D				; $FF0D
L020F: JRE     L0275			; process valid SysEx?
;
; # something SysEx related
;
L0211:
	EQIW    $0F,$00				; skip next if $FF0F is zero (SysEx message length?)
	JR      L0219				; otherwise
	EQI     A,$41				; skip next if accumulator equal to $41 (check SysEx for Roland manufacturer ID)
L0217:
	JR      L01FC				; otherwise SysEx is invalid?
	JR      L0228				; jump when SysEx is good?
;
; # something SysEx related
;
L0219:
	EQIW    $0F,$01				; skip next if $FF0F is 1 (SysEx message length?)
	JR      L022E				; otherwise
	EQI     A,$30				; skip next if equal to $30 (operation code is tone change mode?)
	NEI     A,$31				; skip next if not equal to $31 (operation code is ??? -- undocumented!?)
	JR      L022A				; otherwise operation code is $30 or $31 so jump
	EQI     A,$32				; skip next if equal to $32 (operation code is tone parameter change?)
	JR      L0217				; otherwise SysEx is invalid?
	ANIW    $87,$DF				; $FF87
; fall-through, or jumped to
L0228:
	JRE     L0275				; process valid SysEx?
;
; # handle SysEx operation code
;
L022A: ORIW    $87,$20			; $FF87
L022D: JR      L0228			; jump to shared SysEx processing routine
;
;
;
L022E: EQIW    $0F,$02			; skip next if $FF0F (SysEx message length?) is 2 (unit #?)
L0231: JRE     L0265			; otherwise do something with program change number?
L0233: ANIW    $87,$F1			; $FF87
L0236: OFFIW   $0B,$10			; $FF0B
L0239: JR      L0244			; otherwise
L023A: EQAW    $00				; $FF00
L023D: JR      L0244			; otherwise
L023E: BIT     3,$84			; $FF84
L0240: JR      L0244			; otherwise
L0241: ORIW    $87,$04			; $FF87
L0244: EQAW    $01				; $FF01
L0247: JR      L024E			; otherwise
L0248: BIT     3,$83			; $FF83
L024A: JR      L024E			; otherwise
L024B: ORIW    $87,$08			; $FF87
L024E: EQAW    $02				; $FF02
L0251: JR      L0258			; otherwise
L0252: BIT     3,$85			; $FF85
L0254: JR      L0258			; otherwise
L0255: ORIW    $87,$02			; $FF87
L0258: ONIW    $87,$0E			; $FF87
L025B: JRE     L01FC			; otherwise
L025D: OFFIW   $87,$20			; $FF87
L0260: JR      L0275			; otherwise
L0261: ORIW    $87,$41			; $FF87
L0264: JR      L0271
;
; # seems like program change SysEx handling
;
L0265:
	ORIW    $87,$40				; set bit 6 in $FF87
	ANIW    $87,$FE				; clear bit 0 in $FF87
	LTI     A,$64				; skip next if less than 100
	SUI     A,$64				; otherwise subtract 100 (because program change is forced to 0-99?)
	STAW    $E6					; $FFE6
; fall-through or jumped to
L0271:
	MVIW    $0F,$00				; $FF0F -- zero out SysEx message length?
	JR      L0278				; jump to shared interrupt ending
;
; # process valid SysEx?
;
L0275:
	INRW    $0F					; $FF0F -- increment SysEx message length?
	NOP 						; negates potential skip 
; fall-through or shared interrupt ending   
L0278: 
	EXA     
	EXX     
	EI      
	RETI
;
; # POTENTIALLY TRANSMIT INFO TO MODULE CPU? -- send serial from MAIN to MODULE
;   
L027C: 
	LDAW    $41					; $FF41 -- something with MIDI/serial Tx buffer index?
	EQAW    $40					; $FF40 -- something with MIDI/serial Tx buffer index?
	JR      L0286				; otherwise actually transmit to MODULE
	ORI     MKH,$04
L0285:
	JR      L0278				; jump to shared interrupt ending
;
; # TRANSMIT INFO TO MODULE CPU -- send serial from MAIN to MODULE
;
L0286:
	MVI     H,$FF				; $FFxx
	MOV     L,A
	LDAX    H+					; loads from $FFxx range
	SKIT    FST					; skip next if FST interrupt (serial transmit) is set -- actually clears interrupt here
	NOP     					; negate potential skip
	MOV     TXB,A				; send data to serial output (from MAIN to MODULE)
	MOV     A,L
	LTI     A,$70
	MVI     A,$42				; otherwise
	STAW    $41					; $FF41 -- something with MIDI/serial Tx buffer index?
	JR      L0285				; double-jump to shared interrupt ending
;
; # LED refresh and button switch reading driven by timer interrupt
;
L0297: EXA     
L0298: EXX     
L0299: MOV     A,PF
L029B: ADI     A,$40
L029D: LXI     EA,$0000
L02A0: MOV     EAL,A
L02A1: DSLL    EA
L02A3: DSLL    EA
L02A5: DMOV    B,EA
L02A6: LXI     H,$FF89
L02A9: MVI     PB,$00			; clear LED status?
L02AC: MOV     PF,A				; reset chip select + addressing
L02AE: LDAX    H+B				; $FF89/FF8A/FF8B/FF8C probably, as LED status must be held in at least four banks
L02AF: MOV     PB,A				; update LED status?
L02B1: MOV     A,PA				; read button switches?
L02B3: ANI     A,$1F
L02B5: STAW    $8D				; $FF8D -- update button read state A?
L02B7: MOV     A,B
L02B8: STAW    $8E				; $FF8E -- update button read state B?
L02BA: BIT     7,$A5			; $FFA5
L02BC: DCRW    $A5				; otherwise decrement $FFA5
L02BE: DCRW    $A7				; decrement $FFA7
L02C0: JR      L02C8			; otherwise
L02C1: NEIW    $94,$00			; $FF94
L02C4: JR      L02C8			; otherwise
L02C5: DCRW    $94				; $FF94
L02C7: NOP   					; negate potential skip  
L02C8: JRE     L0278			; jump to shared interrupt ending
;
; # MAIN INITIALIZATION ON CPU BOOT
; # memory mapping, port and timer setup, etc.
;
L02CA: MVI     A,$0E
L02CC: MOV     MM,A				; configures memory mapping
L02CE: MOV     SMH,A			; serial mode high
L02D0: MVI     A,$4E
L02D2: MOV     SML,A			; serial mode low
L02D4: MVI     ANM,$00			; configures Analog to Digital mode
L02D7: MVI     A,$83
L02D9: MOV     MCC,A			; mode control
L02DB: MVI     V,$FF			; sets working register address
L02DD: EXA     					; exchange for alternate registers -- makes working register address the same regardless of registers used
L02DE: MVI     V,$FF			; sets working register address
L02E0: LXI     SP,$0000			; sets stack pointer
L02E3: MVI     A,$00
L02E5: LXI     H,$FF00			; next four lines initialize $FF00~$FFFF (set working registers to all zero)
L02E8: STAX    H+
L02E9: EQI     L,$00
L02EC: JR      L02E8			; otherwise
L02ED: MOV     MC,A				; Port C mode
L02EF: MOV     MB,A				; Port B mode
L02F1: MOV     MF,A				; Port F mode
L02F3: MOV     PF,A
L02F5: MOV     PB,A
L02F7: MOV     ETMM,A
L02F9: MVIW    $00,$00			; $FF00 set to 0
L02FC: MVIW    $01,$02			; $FF01 set to 2
L02FF: MVIW    $02,$01			; $FF02 set to 1
L0302: MVIW    $03,$09			; $FF03 set to 9
L0305: MVI     TMM,$3F
L0308: MVI     A,$1F
L030A: MOV     MA,A				; Port A mode
L030C: MVI     A,$96
L030E: MOV     TM1,A
L0310: MVI     A,$40
L0312: STAW    $B9				; $FFB9
L0314: STAW    $CB				; $FFCB
L0316: STAW    $70				; $FF70
L0318: MVI     A,$0F
L031A: STAW    $83				; $FF83
L031C: STAW    $84				; $FF84
L031E: STAW    $85				; $FF85
L0320: MVIW    $06,$80			; $FF06
L0323: MVIW    $09,$80			; $FF09
L0326: MVIW    $0A,$80			; $FF0A
L0329: MVI     A,$42			; probably because $FF42 is starting address of a related buffer
L032B: STAW    $40				; $FF40 -- something with MIDI/serial Tx buffer index?
L032D: STAW    $41				; $FF41 -- something with MIDI/serial Tx buffer index?
L032F: MVI     A,$12			; probably because $FF12 is starting address of a related buffer
L0331: STAW    $10				; $FF10
L0333: STAW    $11				; $FF11
L0335: MVI     A,$22
L0337: STAW    $20				; $FF20
L0339: STAW    $21				; $FF21
L033B: CALF    L0A69			; initialization
L033D: MOV     ($3FFF),A
L0341: MVI     PC,$0C
L0344: MVIW    $A5,$80			; $FFA5
L0347: MVIW    $E9,$00			; $FFE9
L034A: ANIW    $83,$7F			; $FF83
L034D: LXI     B,$0FFF
L0350: MVI     A,$01
L0352: DIV     A
L0354: DCR     C
L0355: JR      L0350			; otherwise
L0356: DCR     B
L0357: JR      L0350			; otherwise
L0358: ANI     MKL,$FB
L035B: ANI     MKH,$F9
L035E: MOV     A,PA				; read some state from port A (button switches)
L0360: OFFI    A,$01			; skip next if button number 3 is not held
L0362: JMP     L1344			; otherwise jump to TEST MODE when button No. 3 (probably) is held
L0365: OFFI    A,$08			; skip next if not ? bass waveform select ?
L0367: JMP     L1000			; otherwise do something important with engineer, test mode, or similar (button held at power-on)
; fall-through or jumped to by L1008
L036A: EI      
L036B: MVI     A,$80
L036D: CALF    L0E92			; init?
L036F: CALF    L0F79			; init?
L0371: CALF    L0F83			; init?
L0373: CALF    L0F35			; init?
L0375: MOV     A,CR2			; capture dynamic sense value?
L0377: STAW    $A2				; $FFA2 -- dynamic sense value?
L0379: ORI     PC,$08			; set bit 3 in Port C -- bass S/H DMUX inhibit
L037C: ANI     PC,$8F
L037F: LDAW    $D1				; $FFD1
L0381: MOV     ($2800),A
L0385: ANI     PC,$F7
L0388: CALF    L0B94
L038A: CALF    L0EA7
L038C: LDAW    $E9				; $FFE9
L038E: ONIW    $93,$3E
L0391: STAW    $8B				; otherwise update $FF8B
L0393: LDAW    $D2				; $FFD2
L0395: CALF    L09FE
L0397: BIT     7,$08			; $FF08
L0399: JR      L03A8			; otherwise
L039A: ANIW    $08,$7F			; $FF08
L039D: LDAW    $08				; $FF08
L039F: MOV     D,A
L03A0: MVI     A,$D4
L03A2: CALF    L0B88
L03A4: BIT     4,$0B			; $FF0B
L03A6: JR      L03B0			; otherwise
L03A7: JR      L03BD
;
;
;
L03A8: MOV     A,CR0			; capture master tune value?
L03AA: LXI     H,$FFA0
L03AD: CALF    L0A11			; process A/D value
L03AF: NOP     					; negates potential RETS
L03B0: BIT     7,$05			; $FF05
L03B2: JR      L03C1			; otherwise
L03B3: ANIW    $05,$7F			; $FF05
L03B6: OFFIW   $0B,$10			; $FF0B
L03B9: JR      L03C1			; otherwise
L03BA: LDAW    $05				; $FF05
L03BC: MOV     D,A
L03BD: MVI     A,$B4
L03BF: CALF    L0B88
L03C1: LDAW    $07				; $FF07
L03C3: NEAW    $9E				; $FF9E
L03C6: JRE     L03EE			; otherwise
L03C8: STAW    $9E				; $FF9E
L03CA: BIT     4,$0B			; $FF0B
L03CC: JR      L03E0			; otherwise
L03CD: STAW    $9D				; $FF9D
L03CF: CALF    L0F0F
L03D1: JR      L03D9			; can be skipped by RETS
L03D2: MOV     D,A
L03D3: MVI     A,$D2
L03D5: CALF    L0B88
L03D7: JRE     L03FE
;
;
;
L03D9: MOV     D,A
L03DA: MVI     A,$D3
L03DC: CALF    L0B88
L03DE: JRE     L0404
;
;
;
L03E0: CALF    L0F0F
L03E2: JR      L03E9		; can be skipped by RETS
L03E3: MOV     D,A
L03E4: MVI     A,$D2
L03E6: CALF    L0B88
L03E8: JR      L03EE
;
;
;
L03E9: MOV     D,A
L03EA: MVI     A,$D3
L03EC: CALF    L0B88
L03EE: LDAW    $04			; $FF04
L03F0: NEAW    $9D			; $FF9D
L03F3: JR      L0408		; otherwise
L03F4: OFFIW   $0B,$10		; $FF0B
L03F7: JR      L0408		; otherwise
L03F8: STAW    $9D			; $FF9D
L03FA: CALF    L0F0F
L03FC: JR      L0403		; can be skipped by RETS
L03FD: MOV     D,A
L03FE: MVI     A,$B2
L0400: CALF    L0B88
L0402: JR      L0408
;
;
;
L0403: MOV     D,A
L0404: MVI     A,$B3
L0406: CALF    L0B88
L0408: LDAW    $D0			; $FFD0
L040A: CALF    L09FE
L040C: BIT     7,$0A		; $FF0A
L040E: JRE     L0431		; otherwise
L0410: ANIW    $0A,$7F		; $FF0A
L0413: LDAW    $0A			; $FF0A
L0415: ANI     A,$7F
L0417: GTI     A,$13		; skip next if accumulator is greater than 19
L0419: JR      L041D		; otherwise value is 0~19, so jump
L041A: SUI     A,$14		; subtract 20
L041C: JR      L0417		; loop until value is between 0~19
;
; # unknown -- accumulator must be 0~19 to enter this routine
;
L041D: CALF    L0F50
L041F: ORIW    $88,$40		; $FF88
L0422: MVIW    $72,$04		; $FF72
L0425: MVI     B,$09
L0427: MUL     B
L0429: LXI     B,$1F3D		; an offset
L042C: DADD    EA,B
L042E: DMOV    H,EA
L042F: CALF    L09E7
L0431: BIT     7,$09		; $FF09
L0433: JRE     L0459		; otherwise
L0435: CALF    L0F65
L0437: ANIW    $09,$7F		; $FF09
L043A: LDAW    $09			; $FF09
L043C: CALF    L0F57
L043E: ORIW    $88,$40		; $FF88
L0441: MVIW    $72,$01		; $FF72
L0444: LXI     H,$FFBA
L0447: CALF    L0B52
L0449: LXI     D,$FFBA
L044C: CALF    L0B66
L044E: BIT     5,$0B		; $FF0B
L0450: JR      L0459		; otherwise
L0451: MVIW    $72,$03		; $FF72
L0454: LXI     D,$FFBA
L0457: CALF    L0B64
L0459: BIT     7,$06		; $FF06
L045B: JR      L0479		; otherwise
L045C: CALF    L0F70
L045E: ANIW    $06,$7F		; $FF06
L0461: LDAW    $06			; $FF06
L0463: CALF    L0F5E
L0465: ORIW    $88,$40		; $FF88
L0468: MVIW    $72,$02		; $FF72
L046B: LXI     H,$FFA8
L046E: CALF    L0B52
L0470: OFFIW   $0B,$10		; $FF0B
L0473: JR      L0479		; otherwise
L0474: LXI     D,$FFA8
L0477: CALF    L0B64
L0479: LDAW    $D3			; $FFD3
L047B: CALF    L09FE
L047D: BIT     4,$87		; $FF87
L047F: JRE     L04C4		; otherwise
L0481: ANIW    $87,$EF		; $FF87
L0484: BIT     3,$87		; $FF87
L0486: JR      L04A2		; otherwise
L0487: LDAW    $E6			; $FFE6
L0489: CALF    L0F57
L048B: CALL    L1205
L048E: LXI     H,$FFBA
L0491: CALL    L1190
L0494: LXI     D,$FFBA
L0497: CALF    L0B66
L0499: BIT     5,$0B		; $FF0B
L049B: JR      L04A2		; otherwise
L049C: LXI     D,$FFBA
L049F: CALF    L0B64
L04A1: JR      L04B7
;
;
;
L04A2: BIT     2,$87		; $FF87
L04A4: JR      L04B7		; otherwise
L04A5: LDAW    $E6			; $FFE6
L04A7: CALF    L0F5E
L04A9: CALL    L11F8
L04AC: LXI     H,$FFA8
L04AF: CALL    L1190
L04B2: LXI     D,$FFA8
L04B5: CALF    L0B64
L04B7: BIT     1,$87		; $FF87
L04B9: JR      L04C4		; otherwise
L04BA: LDAW    $E6			; $FFE6
L04BC: CALF    L0F50
L04BE: CALL    L1214
L04C1: CALL    L100B
L04C4: LDAW    $87			; $FF87
L04C6: STAW    $E8			; $FFE8
L04C8: ONI     A,$01
L04CA: JRE     L0503		; otherwise
L04CC: CALL    L1178
L04CF: JRE     L04FA		; can be skipped by RETS
L04D1: BIT     2,$87		; $FF87
L04D3: JR      L04DF		; otherwise
L04D4: MVI     C,$A0
L04D6: LXI     H,$FFA8
L04D9: CALL    L10F8
L04DC: CALL    L11F8
L04DF: BIT     3,$87		; $FF87
L04E1: JR      L04ED		; otherwise
L04E2: MVI     C,$C0
L04E4: LXI     H,$FFBA
L04E7: CALL    L10F8
L04EA: CALL    L1205
L04ED: BIT     1,$87		; $FF87
L04EF: JR      L0503		; otherwise
L04F0: LDAW    $E7			; $FFE7
L04F2: MOV     D,A
L04F3: CALL    L105A
L04F6: CALL    L1214
L04F9: JR      L0503
;
;
;
L04FA: OFFIW   $87,$80		; $FF87
L04FD: JR      L0503		; otherwise
L04FE: BIT     7,$E8		; $FFE8
L0500: ANIW    $87,$FE		; $FF87
L0503: LDAW    $CD			; $FFCD
L0505: CALF    L09FE
L0507: CALF    L0B94
L0509: CALF    L0EA7
L050B: LDAW    $9F			; $FF9F
L050D: CALF    L09FE
L050F: LBCD    $FF8D
L0513: LXI     H,$FF8F
L0516: LDAX    H+B
L0517: MOV     D,A
L0518: MOV     A,C
L0519: XRA     D,A
L051B: EQI     D,$00
L051E: JRE     L060B		; otherwise
L0520: MOV     A,CR2		; capture dynamic sense value?
L0522: ONIW    $93,$3E		; $FF93
L0525: JR      L052A		; otherwise
L0526: STAW    $A2			; $FFA2 -- dynamic sense value?
L0528: JRE     L0551
;
;
;
L052A: BIT     0,$93		; $FF93
L052C: JR      L0547		; otherwise
L052D: LXI     H,$FFA2		; dynamic sense value related?
L0530: CALF    L0A11		; process A/D value
L0532: JR      L0551		; can be skipped by RETS
L0533: OFFIW   $8C,$04		; $FF8C
L0536: JR      L053D		; otherwise
L0537: OFFIW   $8C,$01		; $FF8C
L053A: JR      L053F		; otherwise
L053B: MVI     L,$B9
L053D: MVI     L,$70
L053F: MVI     L,$CB
L0541: MVI     H,$FF
L0543: SLR     A
L0545: STAX    H
L0546: JR      L0551
;
;
;
L0547: SUBNBW  $A2			; $FFA2
L054A: NEGA    
L054C: LTI     A,$10
L054E: ORIW    $93,$01		; $FF93
L0551: LDAW    $A4			; $FFA4
L0553: CALF    L09FE
L0555: LDAW    $E9			; $FFE9
L0557: ONIW    $93,$3E		; $FF93
L055A: STAW    $8B			; otherwise update $FF8B
L055C: DCRW    $86			; $FF86
L055E: JR      L0562		; otherwise
L055F: ANIW    $E9,$F7		; $FFE9
L0562: BIT     6,$93		; $FF93
L0564: JR      L0573		; otherwise
L0565: EQIW    $94,$00		; $FF94
L0568: JR      L0573		; otherwise
L0569: ANIW    $93,$3F		; $FF93
L056C: OFFIW   $93,$3C		; $FF93
L056F: JRE     L05D5		; otherwise
L0571: JRE     L05BA
;
;
;
L0573: ONIW    $93,$0E		; $FF93
L0576: JR      L0591		; otherwise
L0577: BIT     5,$93		; $FF93
L0579: EQIW    $A7,$FF		; $FFA7
L057C: JR      L0591		; otherwise
L057D: LXI     H,$FF8B
L0580: ONIW    $93,$0A		; $FF93
L0583: INX     H			; otherwise
L0584: LDAX    H
L0585: ONI     A,$0F
L0587: JR      L058B		; otherwise
L0588: MVI     A,$00
L058A: JR      L058D
;
;
;
L058B: LDAW    $A6			; $FFA6
L058D: STAX    H
L058E: MVIW    $A7,$30		; $FFA7
L0591: BIT     6,$88		; $FF88
L0593: JR      L0597		; otherwise
L0594: OFFIW   $93,$7E		; $FF93
L0597: JRE     L05D5		; otherwise
L0599: OFFIW   $91,$10		; $FF91
L059C: JR      L05A6		; otherwise
L059D: OFFIW   $8F,$10		; $FF8F
L05A0: JR      L05A8		; otherwise
L05A1: BIT     4,$90		; $FF90
L05A3: JR      L05B3		; otherwise
L05A4: MVI     A,$01
L05A6: MVI     A,$04
L05A8: MVI     A,$02
L05AA: OFFI    A,$04
L05AC: JR      L05B5		; otherwise
L05AD: OFFIW   $0B,$20		; $FF0B
L05B0: MVI     A,$03		; otherwise
L05B2: JR      L05B5
;
;
;
L05B3: LDAW    $72			; $FF72
L05B5: STAW    $8C			; $FF8C
L05B7: ANIW    $88,$BF		; $FF88
L05BA: BIT     2,$8C		; $FF8C
L05BC: JR      L05C2		; otherwise
L05BD: LBCD    $FF9B
L05C1: JR      L05CE
;
;
;
L05C2: BIT     0,$8C		; $FF8C
L05C4: JR      L05CA		; otherwise
L05C5: LBCD    $FF99
L05C9: JR      L05CE
;
;
;
L05CA: LBCD    $FF97
L05CE: SBCD    $FF89		; LED related?
L05D2: ANIW    $93,$FE		; $FF93
L05D5: MOV     A,CR1		; capture bass detune value?
L05D7: LXI     H,$FFA1
L05DA: CALF    L0A11		; process A/D value
L05DC: NOP   				; negates potential RETS  
L05DD: LDAW    $CC			; $FFCC
L05DF: CALF    L09FE
L05E1: OFFIW   $A5,$80		; $FFA5
L05E4: JR      L05F0		; otherwise
L05E5: LTIW    $A5,$05		; $FFA5
L05E8: JR      L05F0		; otherwise
L05E9: DI      
L05EA: ANIW    $0B,$7F		; $FF0B
L05ED: JMP     L0329
;
;
;
L05F0: BIT     2,$93		; $FF93
L05F2: JR      L0608		; otherwise
L05F3: LDAW    $95			; $FF95
L05F5: OFFI    A,$80
L05F7: JR      L0608		; otherwise
L05F8: MOV     B,A
L05F9: LDAW    $A2			; $FFA2 -- dynamic sense value?
L05FB: SLR     A
L05FD: MOV     D,A
L05FE: SUBNBW  $96			; $FF96
L0601: NEGA    
L0603: LTI     A,$02
L0605: CALL    L121E		; otherwise
L0608: JMP     L0379
;
;
;
L060B: CALL    L0610
L060E: JRE     L0551
;
;
;
L0610: STAX    H+B
L0611: LTI     B,$03
L0614: JMP     L0823		; otherwise
L0617: BIT     3,$93		; $FF93
L0619: JR      L0629		; otherwise
L061A: OFFIW   $8F,$0F		; $FF8F
L061D: JR      L0629		; otherwise
L061E: OFFIW   $90,$0F		; $FF90
L0621: JR      L0629		; otherwise
L0622: OFFIW   $91,$0F		; $FF91
L0625: JR      L0629		; otherwise
L0626: ANIW    $83,$7F		; $FF83
L0629: ANA     A,D
L062B: ONI     A,$10
L062D: JRE     L0651		; otherwise
L062F: OFFIW   $93,$3E		; $FF93
L0632: RET     				; otherwise return
L0633: MOV     A,B
L0634: NEI     A,$02
L0636: JR      L063C		; otherwise
L0637: NEI     A,$01
L0639: JR      L063E		; otherwise
L063A: MVI     A,$02
L063C: MVI     A,$04
L063E: MVI     A,$01
L0640: OFFI    A,$04
L0642: JR      L0648		; otherwise
L0643: BIT     5,$0B		; $FF0B
L0645: JR      L0648		; otherwise
L0646: MVI     A,$03
L0648: STAW    $72			; $FF72
L064A: ORIW    $88,$40		; $FF88
L064D: ANIW    $93,$3E		; $FF93
L0650: RET
;
;
;    
L0651: ONI     A,$08
L0653: JRE     L0719		; otherwise
L0655: NEI     B,$01
L0658: JRE     L072B		; otherwise
L065A: OFFIW   $92,$0F		; $FF92
L065D: RET 					; otherwise return    
L065E: EQI     B,$02
L0661: JRE     L06BF		; otherwise
L0663: OFFIW   $93,$28		; $FF93
L0666: RET     				; otherwise return
L0667: BIT     4,$93		; $FF93
L0669: JR      L0679		; otherwise
L066A: OFFIW   $93,$80		; $FF93
L066D: RET     				; otherwise return
L066E: ORIW    $88,$20		; $FF88
L0671: MVIW    $8A,$00		; $FF8A
L0674: MVIW    $89,$02		; $FF89
L0677: JRE     L0712
;
;
;
L0679: ONIW    $93,$06		; $FF93
L067C: JR      L0685		; otherwise
L067D: ANIW    $93,$20		; $FF93
L0680: MVIW    $8B,$00		; $FF8B
L0683: JRE     L064A
;
;
;
L0685: BIT     4,$91
L0687: JR      L068B
L0688: MVI     A,$04
L068A: JR      L069B
L068B: BIT     4,$90
L068D: JR      L0691
L068E: MVI     A,$01
L0690: JR      L0696
L0691: BIT     4,$8F
L0693: JR      L06AE
L0694: MVI     A,$02
L0696: OFFIW   $0B,$20
L0699: MVI     A,$03
L069B: ORIW    $93,$04
L069E: MVIW    $8B,$00
L06A1: STAW    $A6
L06A3: ORIW    $95,$80
L06A6: MVIW    $8A,$02
L06A9: MVIW    $89,$02
L06AC: JRE     L064D
L06AE: ORIW    $93,$02
L06B1: MVIW    $8C,$00
L06B4: MVIW    $8A,$02
L06B7: MVIW    $89,$02
L06BA: MVIW    $A6,$0F
L06BD: JRE     L064D
L06BF: OFFIW   $93,$26
L06C2: RET     
L06C3: BIT     3,$93
L06C5: JR      L06CA
L06C6: MVI     A,$0A
L06C8: JRE     L0730
L06CA: OFFIW   $93,$10
L06CD: JRE     L067D
L06CF: ORIW    $93,$10
L06D2: LDAW    $0B
L06D4: ANI     A,$FC
L06D6: MOV     C,A
L06D7: OFFIW   $90,$10
L06DA: JR      L06EA
L06DB: OFFIW   $8F,$10
L06DE: JR      L06EC
L06DF: OFFIW   $91,$10
L06E2: JR      L06EE
L06E3: MVIW    $8C,$00
L06E6: MVI     B,$01
L06E8: MOV     A,C
L06E9: JR      L06F3
L06EA: MVI     A,$01
L06EC: MVI     A,$02
L06EE: MVI     A,$03
L06F0: MOV     B,A
L06F1: ORA     A,C
L06F3: STAW    $0B
L06F5: DCR     B
L06F6: LXI     H,$FF83
L06F9: LDAX    H+B
L06FA: STAW    $8B
L06FC: ANIW    $88,$DF
L06FF: LDAW    $88
L0701: MVIW    $8A,$00
L0704: OFFI    A,$0F
L0706: JR      L070B
L0707: MVIW    $89,$17
L070A: JR      L0715
L070B: CALF    L0A3A
L070D: STAW    $89					; LED related?
L070F: OFFIW   $88,$10
L0712: ORIW    $89,$08
L0715: ANIW    $93,$10
L0718: RET     
L0719: ONI     A,$07
L071B: RET     
L071C: OFFI    A,$01
L071E: JR      L0724
L071F: ONI     A,$02
L0721: JR      L0726
L0722: MVI     A,$06
L0724: MVI     A,$03
L0726: MVI     A,$09
L0728: SUB     A,B
L072A: JR      L072D
L072B: MVI     A,$00
L072D: BIT     3,$93
L072F: JR      L073C
L0730: MVI     C,$40
L0732: OFFIW   $83,$80
L0735: RET     
L0736: ORIW    $83,$80
L0739: CALF    L0F8D
L073B: RET     
L073C: MOV     C,A
L073D: LDAW    $93
L073F: OFFI    A,$80
L0741: JRE     L07AA
L0743: ORI     A,$80
L0745: OFFI    A,$36
L0747: JR      L074D
L0748: ORI     A,$40
L074A: MVIW    $94,$0B
L074D: STAW    $93
L074F: ONI     A,$10
L0751: JR      L0771
L0752: MVIW    $8A,$02
L0755: LDAW    $88
L0757: ANI     A,$E0
L0759: ORA     A,C
L075B: OFFI    A,$20
L075D: ORI     A,$10
L075F: STAW    $88
L0761: OFFI    A,$0F
L0763: JR      L076C
L0764: MVI     A,$17
L0766: OFFIW   $88,$10
L0769: ORI     A,$08
L076B: JR      L076E
L076C: CALF    L0A3A
L076E: STAW    $89					; LED related?
L0770: RET     
L0771: MOV     A,C
L0772: STAW    $0C
L0774: BIT     5,$93
L0776: JR      L078E
L0777: NEI     A,$00
L0779: JR      L0781
L077A: DCR     A
L077B: STAW    $95
L077D: MOV     A,C
L077E: CALF    L0A0C
L0780: JR      L0789
L0781: MVI     A,$02
L0783: ANIW    $93,$7F
L0786: ORIW    $95,$80
L0789: STAW    $89					; LED related?
L078B: MVI     A,$00
L078D: JR      L07A7
L078E: BIT     1,$93
L0790: JR      L0795
L0791: ANIW    $93,$7F
L0794: RET     
L0795: OFFIW   $93,$04
L0798: ORIW    $95,$80
L079B: EQI     A,$00
L079D: JR      L07A1
L079E: MVI     A,$17
L07A0: JR      L07A3
L07A1: CALF    L0A0C
L07A3: STAW    $89					; LED related?
L07A5: MVI     A,$02
L07A7: STAW    $8A
L07A9: RET     
L07AA: ANI     A,$7F
L07AC: STAW    $93
L07AE: ONI     A,$40
L07B0: JR      L07C9
L07B1: ANIW    $93,$3F
L07B4: CALF    L0F24
L07B6: CALF    L0F1A
L07B8: ORI     A,$80
L07BA: BIT     2,$8C
L07BC: JR      L07C0
L07BD: STAW    $0A
L07BF: RET     
L07C0: BIT     0,$8C
L07C2: JR      L07C6
L07C3: STAW    $09
L07C5: RET     
L07C6: STAW    $06
L07C8: RET     
L07C9: ONI     A,$20
L07CB: JR      L07E1
L07CC: CALF    L0F1A
L07CE: NEI     A,$00
L07D0: JR      L07DA
L07D1: DCR     A
L07D2: LTI     A,$10
L07D4: JR      L07DA
L07D5: STAW    $95
L07D7: CALF    L0F24
L07D9: RET     
L07DA: MVIW    $89,$02
L07DD: ORIW    $95,$80
L07E0: RET     
L07E1: ONI     A,$10
L07E3: JRE     L080A
L07E5: LDAW    $88
L07E7: MOV     B,A
L07E8: ANI     A,$0F
L07EA: ANI     B,$D0
L07ED: MVIW    $8A,$00
L07F0: LTI     A,$02
L07F2: JR      L0802
L07F3: EQI     A,$00
L07F5: MVI     A,$0A
L07F7: ADD     A,C
L07F9: LTI     A,$0D
L07FB: JR      L0802
L07FC: ORA     A,B
L07FE: OFFI    A,$0F
L0800: JRE     L075F
L0802: ANI     A,$C0
L0804: STAW    $88
L0806: MVIW    $89,$17
L0809: RET     
L080A: CALF    L0F1A
L080C: LTI     A,$01
L080E: LTI     A,$1B
L0810: JR      L081C
L0811: STAW    $95
L0813: CALF    L0F24
L0815: LDAW    $A2				; $FFA2 -- dynamic sense value?
L0817: SLR     A
L0819: STAW    $96
L081B: RET     
L081C: MVIW    $89,$02
L081F: ORIW    $95,$80
L0822: RET     
L0823: OFFIW   $93,$36
L0826: JRE     L088C
L0828: MOV     A,D
L0829: STAW    $A3
L082B: ONI     A,$04
L082D: JR      L083D
L082E: MVIW    $81,$39
L0831: MVIW    $82,$40
L0834: ONI     C,$04
L0837: JR      L083B
L0838: CALF    L0D0F
L083A: JR      L083D
L083B: CALF    L0E23
L083D: OFFIW   $0B,$20
L0840: JR      L0844
L0841: BIT     1,$A3
L0843: JR      L085F
L0844: MVIW    $81,$45
L0847: MVIW    $82,$40
L084A: BIT     5,$0B
L084C: JR      L0857
L084D: ONIW    $92,$03
L0850: JR      L0854
L0851: CALF    L0C70
L0853: JR      L0861
L0854: CALF    L0DBD
L0856: JR      L0861
L0857: BIT     1,$92
L0859: JR      L085D
L085A: CALF    L0CE7
L085C: JR      L085F
L085D: CALF    L0E01
L085F: BIT     0,$A3
L0861: JR      L0870
L0862: MVIW    $81,$45
L0865: MVIW    $82,$40
L0868: BIT     0,$92
L086A: JR      L086E
L086B: CALF    L0CAA
L086D: JR      L0870
L086E: CALF    L0DE1
L0870: BIT     3,$A3
L0872: RET     
L0873: BIT     3,$92
L0875: RET     
L0876: OFFIW   $93,$08
L0879: JMP     L067D
L087C: MVIW    $A6,$08
L087F: ORIW    $93,$08
L0882: MVIW    $8A,$57
L0885: MVIW    $89,$11
L0888: ANIW    $83,$7F
L088B: RET     
L088C: BIT     2,$93
L088E: JRE     L08B2
L0890: MOV     A,D
L0891: ANI     A,$04
L0893: OFFI    D,$01
L0896: ORI     A,$02
L0898: OFFI    D,$02
L089B: ORI     A,$01
L089D: ANAW    $A6
L08A0: ONI     A,$04
L08A2: JR      L08A5
L08A3: JRE     L082E
L08A5: ONI     A,$03
L08A7: RET     
L08A8: OFFIW   $0B,$20
L08AB: JR      L08B0
L08AC: ONI     A,$01
L08AE: JRE     L0862
L08B0: JRE     L0844
L08B2: BIT     4,$93
L08B4: JRE     L091E
L08B6: ANA     A,D
L08B8: NEI     A,$00
L08BA: RET     
L08BB: MOV     C,A
L08BC: ANI     C,$0C
L08BF: OFFI    A,$01
L08C1: ORI     C,$02
L08C4: OFFI    A,$02
L08C6: ORI     C,$01
L08C9: LXI     H,$FF83
L08CC: LDAW    $0B
L08CE: ANI     A,$03
L08D0: MOV     E,A
L08D1: MOV     B,A
L08D2: NEI     A,$00
L08D4: JR      L08DB
L08D5: DCR     B
L08D6: LDAX    H+B
L08D7: XRA     A,C
L08D9: STAX    H+B
L08DA: JR      L08E7
L08DB: MOV     A,C
L08DC: XRAW    $83
L08DF: STAW    $83
L08E1: ANI     A,$0F
L08E3: STAW    $84
L08E5: STAW    $85
L08E7: STAW    $8B
L08E9: NEI     E,$03
L08EC: RET     
L08ED: ONI     C,$04
L08F0: JR      L0904
L08F1: OFFI    A,$04
L08F3: JR      L0904
L08F4: EQI     E,$00
L08F7: JR      L08FB
L08F8: CALF    L0F79
L08FA: JR      L0902
L08FB: EQI     E,$02
L08FE: JR      L0902
L08FF: CALF    L0F79
L0901: JR      L0904
L0902: CALF    L0F83
L0904: ONI     C,$02
L0907: RET     
L0908: OFFI    A,$02
L090A: RET     
L090B: EQI     E,$00
L090E: JR      L0912
L090F: CALF    L0C59
L0911: JR      L0919
L0912: EQI     E,$02
L0915: JR      L0919
L0916: CALF    L0C59
L0918: RET     
L0919: MVI     D,$00
L091B: CALF    L0C4D
L091D: RET     
L091E: ANA     A,D
L0920: ONI     A,$03
L0922: JR      L0932
L0923: LDAW    $92
L0925: ANI     A,$0F
L0927: EQI     A,$03
L0929: JR      L0932
L092A: OFFIW   $0B,$10
L092D: JR      L0930
L092E: CALF    L0C5E
L0930: JRE     L09B0
L0932: MOV     A,C
L0933: BIT     5,$93
L0935: JRE     L098B
L0937: ANAW    $8B
L093A: EQI     A,$00
L093C: RET     
L093D: STAW    $8B
L093F: OFFIW   $95,$80
L0942: JRE     L0981
L0944: LDAW    $96
L0946: MOV     B,A
L0947: MOV     L,A
L0948: MVI     H,$FF
L094A: LDAW    $95
L094C: STAX    H
L094D: LXI     H,L0022		; mini table (SysEx related?)
L0950: LDAX    H+B
L0951: ANAW    $80
L0954: STAW    $80
L0956: LDAX    H+B
L0957: ANAW    $0E
L095A: STAW    $0E
L095C: EQI     B,$02
L095F: JR      L0964
L0960: CALF    L0E29
L0962: JRE     L0981
;
;
;
L0964: EQI     B,$01
L0967: JR      L0977
L0968: BIT     5,$0B
L096A: JR      L096E
L096B: CALF    L0E30
L096D: JR      L0970
L096E: CALF    L0E68
L0970: CALF    L0F83
L0972: MVI     D,$00
L0974: CALF    L0C4D
L0976: JR      L0981
L0977: EQI     B,$00
L097A: JR      L0981
L097B: CALF    L0E49
L097D: CALF    L0F79
L097F: CALF    L0C59
L0981: ANIW    $93,$02
L0984: MVIW    $8A,$02
L0987: MVIW    $89,$02
L098A: RET     
L098B: ONI     A,$0F
L098D: RET     
L098E: ONI     A,$01
L0990: JR      L0998
L0991: BIT     4,$0B
L0993: JR      L0998
L0994: PUSH    D
L0995: CALF    L0C65
L0997: POP     D
L0998: OFFI    D,$02
L099B: JR      L09B0
L099C: OFFIW   $0B,$20
L099F: JR      L09A4
L09A0: OFFI    D,$01
L09A3: JR      L09B2
L09A4: OFFI    D,$04
L09A7: JR      L09AE
L09A8: ONI     D,$08
L09AB: RET     
L09AC: MVI     A,$03
L09AE: MVI     A,$02
L09B0: MVI     A,$01
L09B2: MVI     A,$00
L09B4: STAW    $96
L09B6: ORIW    $93,$20
L09B9: MOV     L,A
L09BA: NEI     A,$00
L09BC: JR      L09C9
L09BD: NEI     A,$01
L09BF: JR      L09C7
L09C0: NEI     A,$02
L09C2: JR      L09C5
L09C3: MVI     A,$08
L09C5: MVI     A,$04
L09C7: MVI     A,$01
L09C9: MVI     A,$02
L09CB: STAW    $8B
L09CD: MVI     H,$FF
L09CF: LDAX    H
L09D0: STAW    $95
L09D2: ORIW    $95,$80
L09D5: INR     A
L09D6: GTI     A,$09
L09D8: JR      L09DF
L09D9: MVIW    $8A,$44
L09DC: SUI     A,$0A
L09DE: JR      L09E2
L09DF: MVIW    $8A,$00
L09E2: CALF    L0A0C
L09E4: STAW    $89					; $FF89 -- LED related?
L09E6: RET
;
;
;    
L09E7: LXI     D,$FFCC
L09EA: MVI     B,$06
L09EC: LDAX    H+
L09ED: STAX    D+
L09EE: DCR     B
L09EF: JR      L09EC
L09F0: LDAX    H+
L09F1: SLL     A
L09F3: ANI     A,$60
L09F5: BIT     7,$CD
L09F7: ORI     A,$80
L09F9: MOV     PA,A
L09FB: LDAX    H
L09FC: STAX    D
L09FD: RET
;
;
;     
L09FE: ORI     PC,$08
L0A01: ADI     PC,$10
L0A04: MOV     ($2800),A
L0A08: ANI     PC,$F7
L0A0B: RET
;
;
;     
L0A0C: LXI     H,L1724			; data table
L0A0F: LDAX    H+A
L0A10: RET
;
; # handle analog to digital values
;     
L0A11: MOV     B,A
L0A12: SUBNBX  H
L0A14: NEGA    
L0A16: GTI     A,$01
L0A18: RET     
L0A19: MOV     A,B
L0A1A: STAX    H
L0A1B: RETS
;
;
;   
L0A1C: GTI     A,$17
L0A1E: JR      L0A25
L0A1F: GTI     A,$6C
L0A21: RET     
L0A22: SUI     A,$0C
L0A24: JR      L0A1F
L0A25: ADI     A,$0C
L0A27: JR      L0A1C
L0A28: MOV     B,A
L0A29: LDAW    $88
L0A2B: ANI     A,$0F
L0A2D: BIT     4,$88
L0A2F: JR      L0A36
L0A30: SUBNB   B,A
L0A32: ADI     B,$0C
L0A35: JR      L0A38
L0A36: ADD     B,A
L0A38: MOV     A,B
L0A39: RET     
L0A3A: ANI     A,$0F
L0A3C: GTI     A,$09
L0A3E: JR      L0A44
L0A3F: SUI     A,$0A
L0A41: MVIW    $8A,$44		; $FF8A -- LED related?
L0A44: CALF    L0A0C
L0A46: OFFIW   $88,$10
L0A49: ORI     A,$08
L0A4B: RET     
L0A4C: ANI     A,$7F
L0A4E: MOV     E,A
L0A4F: LXI     EA,$0000
L0A52: MOV     EAL,A
L0A53: MVI     A,$0A
L0A55: DIV     A
L0A57: CALF    L0A0C
L0A59: MOV     C,A
L0A5A: MOV     A,EAL
L0A5B: NEI     A,$00
L0A5D: JR      L0A60
L0A5E: LDAX    H+A
L0A5F: JR      L0A66
L0A60: MVI     A,$17
L0A62: NEI     C,$E7
L0A65: MOV     C,A
L0A66: MOV     B,A
L0A67: MOV     A,E
L0A68: RET
;
; # initialization of some type
;     
L0A69: LXI     H,$FF73
L0A6C: MVI     A,$01
L0A6E: STAX    H+
L0A6F: INR     A
L0A70: EQI     A,$07
L0A72: JR      L0A6E
L0A73: MVI     A,$00
L0A75: STAX    H+
L0A76: MVI     B,$05
L0A78: MVI     A,$80
L0A7A: STAX    H+
L0A7B: DCR     B
L0A7C: JR      L0A7A
L0A7D: RET 
;
;
;    
L0A7E: LDAW    $10
L0A80: CALF    L0A94
L0A82: RET					; can be skipped by RETS    
L0A83: MOV     E,A
L0A84: LDAW    $0D
L0A86: ORI     A,$80
L0A88: MVI     H,$FF
L0A8A: STAX    H
L0A8B: MOV     A,E
L0A8C: CALF    L0A94
L0A8E: RET					; can be skipped by RETS     
L0A8F: STAW    $10
L0A91: MOV     A,C
L0A92: STAX    H
L0A93: RET
;
;
;     
L0A94: MOV     L,A
L0A95: INR     A
L0A96: NEI     A,$20
L0A98: MVI     A,$12		; otherwise
L0A9A: NEAW    $11			; $FF11
L0A9D: RET					; otherwise     
L0A9E: RETS
;
;
;    
L0A9F: LDAW    $20
L0AA1: MOV     L,A
L0AA2: INR     A
L0AA3: NEI     A,$40
L0AA5: MVI     A,$22
L0AA7: NEAW    $21
L0AAA: JR      L0AB2
L0AAB: STAW    $20
L0AAD: MOV     A,C
L0AAE: MVI     H,$FF
L0AB0: STAX    H
L0AB1: RET     
L0AB2: ORIW    $0B,$40
L0AB5: RET     
L0AB6: MVI     A,$90
L0AB8: ORA     A,B
L0ABA: CALF    L0B36
L0ABC: LDAW    $81
L0ABE: CALF    L0A28
L0AC0: CALF    L0A1C
L0AC2: CALF    L0B36
L0AC4: MOV     A,D
L0AC5: CALF    L0B36
L0AC7: RET     
L0AC8: BIT     6,$82
L0ACA: JR      L0ADE
L0ACB: MOV     D,A
L0ACC: MVI     C,$7F
L0ACE: SUB     C,A
L0AD0: LDAW    $82
L0AD2: SUI     A,$40
L0AD4: SLL     A
L0AD6: SLL     A
L0AD8: MUL     C
L0ADA: MOV     A,EAH
L0ADB: ADD     D,A
L0ADD: JR      L0AE9
L0ADE: MOV     C,A
L0ADF: LDAW    $82
L0AE1: SLL     A
L0AE3: SLL     A
L0AE5: MUL     C
L0AE7: MOV     A,EAH
L0AE8: MOV     D,A
L0AE9: GTI     D,$08
L0AEC: MVI     D,$08
L0AEE: RET
;
;
;     
L0AEF: MOV     A,L
L0AF0: INR     A
L0AF1: NEI     A,$40
L0AF3: MVI     A,$22
L0AF5: RET
;
;
;     
L0AF6: LDAX    D
L0AF7: MOV     B,A
L0AF8: NEI     A,$00
L0AFA: RET     
L0AFB: LDAX    H+
L0AFC: STAX    D+
L0AFD: EQI     A,$00
L0AFF: JR      L0AFB
L0B00: RET
;
;
;     
L0B01: LDAW    $81			; $FF81
L0B03: MOV     C,A
L0B04: NEAX    H
L0B06: RETS					; otherwise    
L0B07: ORI     A,$80
L0B09: NEAX    H+
L0B0B: RET					; otherwise    
L0B0C: INR     B
L0B0D: MOV     A,C
L0B0E: EQI     B,$06
L0B11: JR      L0B04		; otherwise
L0B12: RETS
;
;
;    
L0B13: NEAX    H+
L0B15: JR      L0B18
L0B16: INX     D
L0B17: JR      L0B13
L0B18: LDAX    H+
L0B19: STAX    D+
L0B1A: EQI     A,$00
L0B1C: JR      L0B18
L0B1D: RET
;
;
;     
L0B1E: LDAW    $81			; $FF81
L0B20: NEAX    H+
L0B22: RETS 				; otherwise   
L0B23: INR     B
L0B24: EQI     B,$06
L0B27: JR      L0B20		; otherwise
L0B28: RET
;
;
;    
L0B29: DCX     H
L0B2A: ORI     A,$80
L0B2C: STAX    H
L0B2D: MOV     A,B
L0B2E: MOV     D,A
L0B2F: MVI     A,$80
L0B31: ORA     A,B
L0B33: CALF    L0B36
L0B35: RET
;
; init MODULE related? -- sends info to MODULE over serial
;     
L0B36: MOV     C,A
L0B37: LDAW    $40			; $FF40 -- load current serial Tx index?
L0B39: MOV     L,A
L0B3A: INR     A
L0B3B: NEI     A,$70		; skip if index hasn't hit $FF70?
L0B3D: MVI     A,$42		; otherwise roll over to $FF42 (start of serial Tx buffer?)
L0B3F: NEAW    $41			; $FF41 -- infinite loop which can only be broken by interrupt -- compare to pending serial Tx index?
L0B42: JR      L0B3F
L0B43: MOV     B,A
L0B44: MVI     H,$FF		; $FFxx
L0B46: MOV     A,C
L0B47: STAX    H
L0B48: MOV     A,B
L0B49: ORI     MKH,$06
L0B4C: STAW    $40			; $FF40 -- update current serial Tx index?
L0B4E: ANI     MKH,$F9
L0B51: RET
;
;
;     
L0B52: MOV     B,A
L0B53: MVI     A,$11
L0B55: MUL     B
L0B57: LXI     B,$1800			; large offset
L0B5A: DADD    EA,B
L0B5C: DMOV    D,EA
L0B5D: MVI     B,$10
L0B5F: LDAX    D+
L0B60: STAX    H+
L0B61: DCR     B
L0B62: JR      L0B5F
L0B63: RET
;
;
;     
L0B64: MVI     A,$A2
L0B66: MVI     A,$C2
L0B68: MOV     C,A
L0B69: DMOV    EA,D
L0B6A: PUSH    B
L0B6B: CALF    L0B36
L0B6D: POP     B
L0B6E: INX     D
L0B6F: INX     D
L0B70: MVI     B,$0E
L0B72: LDAX    D+
L0B73: ANI     A,$7F
L0B75: PUSH    B
L0B76: CALF    L0B36
L0B78: POP     B
L0B79: DCR     B
L0B7A: JR      L0B72
L0B7B: MOV     A,C
L0B7C: ANI     A,$E0
L0B7E: CALF    L0B36
L0B80: DMOV    D,EA
L0B81: LDAX    D+
L0B82: CALF    L0B36
L0B84: LDAX    D
L0B85: CALF    L0B36
L0B87: RET
;
;
;     
L0B88: CALF    L0B36
L0B8A: MOV     A,D
L0B8B: ANI     A,$7F
L0B8D: CALF    L0B36
L0B8F: RET
;
;
;     
L0B90: MOV     A,L
L0B91: STAW    $21
L0B93: JR      L0B9D
;
; # init related?
;
L0B94: LDAW    $21
L0B96: NEAW    $20
L0B99: RET     
L0B9A: MOV     L,A
L0B9B: MVI     H,$FF
L0B9D: LDAX    H
L0B9E: ONI     A,$80
L0BA0: JR      L0BB2
L0BA1: STAW    $80
L0BA3: LTI     A,$A0
L0BA5: JR      L0BC2
L0BA6: CALF    L0AEF
L0BA8: NEAW    $20
L0BAB: RET     
L0BAC: MOV     L,A
L0BAD: LDAX    H
L0BAE: OFFI    A,$80
L0BB0: JRE     L0B90
L0BB2: STAW    $81
L0BB4: CALF    L0AEF
L0BB6: NEAW    $20
L0BB9: RET     
L0BBA: MOV     L,A
L0BBB: LDAX    H
L0BBC: OFFI    A,$80
L0BBE: JRE     L0B90
L0BC0: STAW    $82
L0BC2: CALF    L0AEF
L0BC4: STAW    $21
L0BC6: LDAW    $80
L0BC8: LTI     A,$A0
L0BCA: JRE     L0C05
L0BCC: GTI     A,$8F
L0BCE: JR      L0BD2
L0BCF: NEIW    $82,$00
L0BD2: JR      L0BEC
L0BD3: BIT     5,$0B
L0BD5: JR      L0BDC
L0BD6: ONI     A,$02
L0BD8: JR      L0BE6
L0BD9: CALF    L0C70
L0BDB: JR      L0BE6
L0BDC: ONI     A,$01
L0BDE: JR      L0BE1
L0BDF: CALF    L0CAA
L0BE1: BIT     1,$80
L0BE3: JR      L0BE6
L0BE4: CALF    L0CE7
L0BE6: BIT     2,$80
L0BE8: RET     
L0BE9: CALF    L0D0F
L0BEB: RET
;
;     
L0BEC: BIT     5,$0B
L0BEE: JR      L0BF5
L0BEF: ONI     A,$02
L0BF1: JR      L0BFF
L0BF2: CALF    L0DBD
L0BF4: JR      L0BFF
L0BF5: ONI     A,$01
L0BF7: JR      L0BFA
L0BF8: CALF    L0DE1
L0BFA: BIT     1,$80
L0BFC: JR      L0BFF
L0BFD: CALF    L0E01
L0BFF: BIT     2,$80
L0C01: RET     
L0C02: CALF    L0E23
L0C04: RET     
L0C05: LTI     A,$C0
L0C07: JR      L0C21
L0C08: BIT     5,$0B
L0C0A: JR      L0C11
L0C0B: ONI     A,$02
L0C0D: JR      L0C1B
L0C0E: CALF    L0E30
L0C10: JR      L0C1B
;
;
;
L0C11: ONI     A,$01
L0C13: JR      L0C16
L0C14: CALF    L0E49
L0C16: BIT     1,$80
L0C18: JR      L0C1B
L0C19: CALF    L0E68
L0C1B: BIT     2,$80
L0C1D: RET     
L0C1E: CALF    L0E29
L0C20: RET
;
;
;   
L0C21: LTI     A,$D0
L0C23: JR      L0C31
L0C24: EQI     A,$C0
L0C26: JR      L0C2B
L0C27: CALL    L1300
L0C2A: RET
;
;
;   
L0C2B: NEI     A,$C1
L0C2D: CALL    L130D
L0C30: RET
;
;
; 
L0C31: LTI     A,$E0
L0C33: RET     
L0C34: MOV     D,A
L0C35: ONI     A,$08
L0C37: JR      L0C4A
L0C38: ONI     A,$02
L0C3A: JR      L0C45
L0C3B: MVI     A,$88
L0C3D: CALF    L0B36
L0C3F: BIT     5,$0B
L0C41: JR      L0C45
L0C42: MVI     A,$86
L0C44: JR      L0C5B
L0C45: ONI     D,$01
L0C48: RET     
L0C49: JR      L0C42
L0C4A: ONI     A,$02
L0C4C: JR      L0C55
L0C4D: MVI     A,$89
L0C4F: CALF    L0B36
L0C51: OFFIW   $0B,$20
L0C54: JR      L0C59
L0C55: ONI     D,$01
L0C58: RET     
L0C59: MVI     A,$87
L0C5B: CALF    L0B36
L0C5D: RET
;
;
;    
L0C5E: ORIW    $0B,$10
L0C61: CALL    L1300
L0C64: JR      L0C6B
;
;
;
L0C65: ANIW    $0B,$EF
L0C68: CALL    L130D
L0C6B: CALF    L0F79
L0C6D: CALF    L0F83
L0C6F: RET
;
;
;    
L0C70: LXI     H,$FF7A
L0C73: MVI     B,$00
L0C75: CALF    L0B01
L0C77: JRE     L0C9A		; can be skipped by RETS
;
L0C79: EQI     B,$06
L0C7C: JR      L0C8A
L0C7D: LXI     D,$FF73
L0C80: LXI     H,$FF74
L0C83: CALF    L0AF6
L0C85: NEI     B,$00
L0C88: RET     
L0C89: DCR     B
L0C8A: LXI     H,$FF7A
L0C8D: LDAW    $81
L0C8F: STAX    H+B
L0C90: LDAW    $CB
L0C92: CALF    L0AC8
L0C94: CALF    L0AB6
L0C96: ORIW    $E9,$01
L0C99: RET
;
;
;    
L0C9A: MOV     A,B
L0C9B: INR     A
L0C9C: LXI     H,$FF73
L0C9F: LXI     D,$FF73
L0CA2: CALF    L0B13
L0CA4: JR      L0C8A
L0CA5: SUI     B,$04
L0CA8: JRE     L0CD7
L0CAA: LXI     H,$FF7A
L0CAD: MVI     B,$04
L0CAF: CALF    L0B01
L0CB1: JR      L0CC6		; can be skipped by RETS
;
L0CB2: EQI     B,$06
L0CB5: JR      L0CA5
L0CB6: NEIW    $73,$00
L0CB9: RET     
L0CBA: LDAW    $73
L0CBC: DCR     A
L0CBD: MOV     B,A
L0CBE: LDAW    $74
L0CC0: STAW    $73
L0CC2: MVIW    $74,$00
L0CC5: JR      L0CD7
L0CC6: MOV     A,B
L0CC7: SUI     A,$03
L0CC9: MOV     B,A
L0CCA: DCR     B
L0CCB: LXI     H,$FF73
L0CCE: EQAX    H+
L0CD0: JR      L0CD4
L0CD1: LDAX    H
L0CD2: STAW    $73
L0CD4: MVIW    $74,$00
L0CD7: LXI     H,$FF7A
L0CDA: LDAW    $81
L0CDC: STAX    H+B
L0CDD: LDAW    $B9
L0CDF: CALF    L0AC8
L0CE1: CALF    L0AB6
L0CE3: ORIW    $E9,$02
L0CE6: RET
;
;
;     
L0CE7: LXI     H,$FF7C
L0CEA: MVI     B,$02
L0CEC: CALF    L0B01
L0CEE: JR      L0D05			; can be skipped by RETS
;
L0CEF: EQI     B,$06
L0CF2: JR      L0D00
L0CF3: LXI     D,$FF75
L0CF6: LXI     H,$FF76
L0CF9: CALF    L0AF6
L0CFB: NEI     B,$00
L0CFE: RET     
L0CFF: DCR     B
L0D00: LXI     H,$FF7A
L0D03: JRE     L0C8D
L0D05: MOV     A,B
L0D06: INR     A
L0D07: LXI     EA,$FF75
L0D0A: DMOV    D,EA
L0D0B: DMOV    H,EA
L0D0C: CALF    L0B13
L0D0E: JR      L0D00
;
; # sub-routine
;
L0D0F: LDAW    $81
L0D11: STAW    $71
L0D13: CALF    L0A28
L0D15: CALF    L0DB1
L0D17: MOV     C,A
L0D18: SUINB   A,$24
L0D1A: MVI     A,$00
L0D1C: LTI     A,$34
L0D1E: MVI     A,$33
L0D20: MOV     B,A
L0D21: SLL     A
L0D23: SLL     A
L0D25: ADD     B,A
L0D27: LDAW    $CF
L0D29: MUL     B
L0D2B: MOV     A,EAH
L0D2C: STAW    $A4
L0D2E: MOV     A,C
L0D2F: LXI     EA,$0018
L0D32: MOV     EAH,A
L0D33: LDAW    $A0
L0D35: ONI     A,$80
L0D37: JR      L0D3D
L0D38: ANI     A,$7F
L0D3A: EADD    EA,A
L0D3C: JR      L0D43
;
; # sub-routine
;
L0D3D: XRI     A,$FF
L0D3F: ANI     A,$7F
L0D41: ESUB    EA,A
L0D43: LDAW    $A1
L0D45: ONI     A,$80
L0D47: JR      L0D4D
L0D48: ANI     A,$7F
L0D4A: EADD    EA,A
L0D4C: JR      L0D53
;
; # sub-routine
;
L0D4D: XRI     A,$FF
L0D4F: ANI     A,$7F
L0D51: ESUB    EA,A
L0D53: MOV     A,EAL
L0D54: PUSH    V
L0D55: MOV     A,EAH
L0D56: SUI     A,$18
L0D58: LXI     EA,$1750
L0D5B: SLL     A
L0D5D: EADD    EA,A
L0D5F: DMOV    H,EA
L0D60: LDEAX   H+$02
L0D63: DMOV    B,EA
L0D64: LDEAX   H
L0D66: DMOV    D,EA
L0D67: DSUB    EA,B
L0D69: DMOV    B,EA
L0D6A: POP     V
L0D6B: MUL     C
L0D6D: MOV     EAL,A
L0D6E: MOV     A,EAH
L0D6F: MOV     C,A
L0D70: MOV     A,EAL
L0D71: MUL     B
L0D73: EADD    EA,C
L0D75: DMOV    B,EA
L0D76: DMOV    EA,D
L0D77: DSUB    EA,B
L0D79: MVI     A,$00
L0D7B: MOV     ETMM,A
L0D7D: MVI     EOM,$70
L0D80: DMOV    ETM1,EA
L0D82: OFFIW   $CD,$80
L0D85: JR      L0D8D
L0D86: ONIW    $CC,$C0
L0D89: JR      L0D91
L0D8A: OFFIW   $CC,$80
L0D8D: DSLR    EA
L0D8F: DSLR    EA
L0D91: DSLR    EA
L0D93: DSLR    EA
L0D95: DMOV    ETM0,EA
L0D97: MVI     A,$CC
L0D99: MOV     ETMM,A
L0D9B: LDAW    $70
L0D9D: CALF    L0AC8
L0D9F: MOV     A,D
L0DA0: SLL     A
L0DA2: MOV     B,A
L0DA3: LDAW    $CE
L0DA5: MUL     B
L0DA7: MOV     A,EAH
L0DA8: STAW    $9F
L0DAA: ANI     PC,$FB
L0DAD: ORIW    $E9,$04
L0DB0: RET
;
;
;    
L0DB1: GTI     A,$1E
L0DB3: JR      L0DBA
L0DB4: GTI     A,$60
L0DB6: RET     
L0DB7: SUI     A,$0C
L0DB9: JR      L0DB4
L0DBA: ADI     A,$0C
L0DBC: JR      L0DB1
L0DBD: LXI     H,$FF7A
L0DC0: MVI     B,$00
L0DC2: CALF    L0B1E
L0DC4: RET					; can be skipped by RETS
;
L0DC5: CALF    L0B29
L0DC7: LXI     H,$FF77
L0DCA: MVI     A,$00
L0DCC: EQAX    H-
L0DCE: JR      L0DD4
L0DCF: EQI     L,$72
L0DD2: JR      L0DCC
L0DD3: JR      L0DD5
;
;
;
L0DD4: INX     H
L0DD5: INX     H
L0DD6: MOV     A,D
L0DD7: INR     A
L0DD8: STAX    H
L0DD9: NEIW    $78,$00
L0DDC: RET     
L0DDD: ANIW    $E9,$FE
L0DE0: RET
;
;
;    
L0DE1: LXI     H,$FF7A
L0DE4: MVI     B,$04
L0DE6: CALF    L0B1E
L0DE8: RET					; can be skipped by RETS
;
L0DE9: SUI     B,$04
L0DEC: CALF    L0B29
L0DEE: LXI     H,$FF73
L0DF1: MVI     A,$00
L0DF3: EQAX    H
L0DF5: INX     H
L0DF6: MOV     A,D
L0DF7: INR     A
L0DF8: STAX    H
L0DF9: NEIW    $74,$00
L0DFC: RET     
L0DFD: ANIW    $E9,$FD
L0E00: RET
;
;
;     
L0E01: LXI     H,$FF7C
L0E04: MVI     B,$02
L0E06: CALF    L0B1E
L0E08: RET					; can be skipped by RETS
;
L0E09: CALF    L0B29
L0E0B: LXI     H,$FF77
L0E0E: MVI     A,$00
L0E10: EQAX    H-
L0E12: JR      L0E18
L0E13: EQI     L,$74
L0E16: JR      L0E10
L0E17: JR      L0E19
;
;
;
L0E18: INX     H
L0E19: INX     H
L0E1A: MOV     A,D
L0E1B: INR     A
L0E1C: STAX    H
L0E1D: NEIW    $78,$00
L0E20: RET     
L0E21: JRE     L0DDD
L0E23: LDAW    $81
L0E25: EQAW    $71
L0E28: RET     
L0E29: ORI     PC,$04
L0E2C: ANIW    $E9,$FB
L0E2F: RET
;
;
;     
L0E30: LXI     H,$FF7A
L0E33: LXI     B,$0500
L0E36: CALF    L0E81
L0E38: NEI     C,$00
L0E3B: JR      L0E47
L0E3C: LXI     H,$FF73
L0E3F: MVI     A,$01
L0E41: CALF    L0E8C
L0E43: MVI     A,$80
L0E45: CALF    L0E92
L0E47: JRE     L0DDD
;
;
;
L0E49: ONIW    $7A,$80
L0E4C: JR      L0E51
L0E4D: OFFIW   $7B,$80
L0E50: JR      L0E66
L0E51: ORIW    $7A,$80
L0E54: ORIW    $7B,$80
L0E57: MVI     A,$01
L0E59: STAW    $73
L0E5B: INR     A
L0E5C: STAW    $74
L0E5E: MVI     A,$80
L0E60: CALF    L0B36
L0E62: MVI     A,$81
L0E64: CALF    L0B36
L0E66: JRE     L0DFD
;
;
;
L0E68: LXI     H,$FF7C
L0E6B: LXI     B,$0300
L0E6E: CALF    L0E81
L0E70: NEI     C,$00
L0E73: JR      L0E7F
L0E74: LXI     H,$FF75
L0E77: MVI     A,$03
L0E79: CALF    L0E8C
L0E7B: MVI     A,$82
L0E7D: CALF    L0E92
L0E7F: JRE     L0DDD
;
;
;
L0E81: LDAX    H
L0E82: ONI     A,$80
L0E84: MVI     C,$01
L0E86: ORI     A,$80
L0E88: STAX    H+
L0E89: DCR     B
L0E8A: JR      L0E81
L0E8B: RET
;
;
;     
L0E8C: STAX    H+
L0E8D: INR     A
L0E8E: EQI     A,$07
L0E90: JR      L0E8C
L0E91: RET 
;
; # probably an initialization
;    
L0E92: PUSH    V
L0E93: CALF    L0B36
L0E95: POP     V
L0E96: INR     A
L0E97: EQI     A,$86
L0E99: JR      L0E92
L0E9A: RET
;
;
;     
L0E9B: MOV     A,L
L0E9C: INR     A
L0E9D: NEI     A,$20
L0E9F: MVI     A,$12
L0EA1: RET     
L0EA2: CALF    L0E9B
L0EA4: STAW    $11
L0EA6: JR      L0EA9
L0EA7: LDAW    $11
L0EA9: NEAW    $10
L0EAC: RET     
L0EAD: MOV     L,A
L0EAE: MVI     H,$FF
L0EB0: LDAX    H
L0EB1: ONI     A,$80
L0EB3: JR      L0EA2
L0EB4: ANI     A,$7F
L0EB6: MOV     B,A
L0EB7: CALF    L0E9B
L0EB9: NEAW    $10				; $FF10
L0EBC: RET 						; otherwise return    
L0EBD: MOV     L,A
L0EBE: LDAX    H
L0EBF: OFFI    A,$80
L0EC1: JR      L0EB0			; otherwise
L0EC2: MOV     C,A
L0EC3: CALF    L0E9B
L0EC5: STAW    $11				; $FF11
L0EC7: MOV     A,B
L0EC8: GTI     A,$22			; skip next if accumulator is greater than 34
L0ECA: RET     					; otherwise 34 or less, so return
L0ECB: LTI     A,$34			; skip next if accumulator is less than 52
L0ECD: RET     					; otherwise 52 or more, so return
L0ECE: SUI     A,$23			; subtract 35
L0ED0: SLL     A				; double the offset because table holds 16-bit values
L0ED2: LXI     H,L172E			; data table
L0ED5: LDEAX   H+A				; get 2 byte value from table
L0ED7: LXI     D,$3000
L0EDA: MOV     A,C
L0EDB: SLR     A
L0EDD: STAX    D				; write to peripheral?
L0EDE: MOV     A,B
L0EDF: EQI     A,$2A
L0EE1: NEI     A,$2C
L0EE3: JR      L0EEB			; otherwise
L0EE4: EQI     A,$2E
L0EE6: JR      L0EEF			; otherwise
L0EE7: ORIW    $88,$80			; $FF88
L0EEA: JR      L0EF5
;
;
;
L0EEB: ANIW    $88,$7F
L0EEE: JR      L0EF5
;
;
;
L0EEF: MOV     A,EAH
L0EF0: BIT     7,$88
L0EF2: ORI     A,$04
L0EF4: MOV     EAH,A
L0EF5: DMOV    H,EA
L0EF6: STAX    H
L0EF7: MVI     L,$FF
L0EF9: ORI     H,$03
L0EFC: DIV     A
L0EFE: DIV     A
L0F00: DIV     A
L0F02: BIT     7,$88
L0F04: ORI     H,$04
L0F07: STAX    H
L0F08: ORIW    $E9,$08
L0F0B: MVIW    $86,$80
L0F0E: RET
;
;
;     
L0F0F:
	ONI     A,$80
	JR      L0F15
	ANI     A,$7F
	RETS
;
;
; 
L0F15: XRI     A,$FF
L0F17: ANI     A,$7F
L0F19: RET     
L0F1A: LDAW    $0C
L0F1C: MVI     B,$0A
L0F1E: MUL     B
L0F20: EADD    EA,C
L0F22: MOV     A,EAL
L0F23: RET
;
;
;    
L0F24: LDAW    $89					; $FF89 -- LED related?
L0F26: STAW    $8A					; $FF8A -- LED related?
L0F28: MOV     A,C
L0F29: EQI     A,$00
L0F2B: JR      L0F30
L0F2C: NEIW    $89,$17				; $FF89 -- LED related?
L0F2F: JR      L0F34
L0F30: CALF    L0A0C
L0F32: STAW    $89					; $FF89 -- LED related?
L0F34: RET
;
; some initialization probably
;     
L0F35: MVI     D,$00
L0F37: MVI     A,$B2
L0F39: CALF    L0B88
L0F3B: MVI     A,$B4
L0F3D: CALF    L0B88
L0F3F: MVI     A,$D2
L0F41: CALF    L0B88
L0F43: MVI     A,$D4
L0F45: CALF    L0B88
L0F47: MVI     A,$87
L0F49: CALF    L0B36
L0F4B: MVI     A,$89
L0F4D: CALF    L0B36
L0F4F: RET
;
;
;     
L0F50: CALF    L0A4C
L0F52: SBCD    $FF9B
L0F56: RET
;
;
;     
L0F57: CALF    L0A4C
L0F59: SBCD    $FF99
L0F5D: RET 
;
;
;    
L0F5E: CALF    L0A4C
L0F60: SBCD    $FF97
L0F64: RET    
;
;
; 
L0F65: MVI     A,$CF
L0F67: CALF    L0B36
L0F69: MVI     A,$00
L0F6B: CALF    L0B36
L0F6D: BIT     5,$0B
L0F6F: RET     
L0F70: MVI     A,$AF
L0F72: CALF    L0B36
L0F74: MVI     A,$00
L0F76: CALF    L0B36
L0F78: RET 
;
; some initialization probably
;    
L0F79: MVIW    $04,$80
L0F7C: MVIW    $05,$80
L0F7F: MVIW    $9D,$00
L0F82: RET 
;
; some initialization probably
;    
L0F83: MVIW    $07,$80
L0F86: MVIW    $08,$80
L0F89: MVIW    $9E,$00
L0F8C: RET   
;
;
;  
L0F8D: LXI     H,L16B5			; data table
L0F90: LDAX    H+A
L0F91: MOV     B,A
L0F92: CALF    L0EC7
L0F94: RET 
;
; # FILLER TO KEEP ALIGNMENT TO $1000
;    
L0F95: 	
	rept (107)
		DB	$00
	endm
;
; # probably engineer mode, test mode or similar
;   
L1000: STAW    $8F				; $FF8F
L1002: MOV     A,(L0006)		; beyond stupid to use vector table area to hold one constant byte...
L1006: STAW    $06				; $FF06
L1008: JMP     L036A
;
;
;
L100B: LDAW    $D7				; $FFD7
L100D: LTI     A,$60
L100F: JR      L1015
L1010: LTI     A,$40
L1012: JR      L1017
L1013: MVI     A,$00
L1015: MVI     A,$80
L1017: MVI     A,$40
L1019: MOV     C,A
L101A: LXI     H,$FFD9
L101D: LXI     D,$FFCC
L1020: LDAX    H+
L1021: SLR     A
L1023: ANI     A,$3F
L1025: ORA     A,C
L1027: STAX    D+
L1028: LDAX    H+
L1029: SLR     A
L102B: OFFIW   $E4,$10
L102E: ORI     A,$80
L1030: MOV     C,A
L1031: STAX    D+
L1032: LDAX    H+
L1033: SLR     A
L1035: STAX    D+
L1036: INX     H
L1037: MVI     B,$03
L1039: LDAX    H+
L103A: SLR     A
L103C: STAX    D+
L103D: DCR     B
L103E: JR      L1039
L103F: LDAX    H+
L1040: ANI     A,$60
L1042: ANI     C,$80
L1045: ORA     A,C
L1047: XRI     A,$80
L1049: MOV     PA,A
L104B: LDAX    H
L104C: SLR     A
L104E: STAX    D
L104F: RET
;
;
;     
L1050: EQI     B,$04			; skip next if B is 4
L1053: JR      L1055			; otherwise B is not 4, so hop over next line
L1054: DCR     B				; reduce B from 4 to 3
L1055: NEI     B,$14			; skip next if B is not 20
L1058: JRE     L10CD			; otherwise B is 20, so jump
L105A: LXI     H,L10E0			; has to be data table
L105D: LDAX    H+B				; read value from table
L105E: NEI     A,$00			; skip next if table value was not zero
L1060: RET						; otherwise table value was zero, so return     
L1061: NEI     A,$01			; skip next if table value was not 1
L1063: JRE     L107F			; otherwise table value was 1, so jump
L1065: NEI     A,$0A			; skip next if table value was not $0A
L1067: JRE     L108E			; otherwise table value was $0A, so jump
L1069: NEI     A,$09			; skip next if table value was not 9
L106B: JRE     L10A5			; otherwise table value was 9, so jump
L106D: NEI     A,$0B			; skip next if table value was not $0B
L106F: JRE     L10AF			; otherwise table value was $0B, so jump
L1071: NEI     A,$02			; skip next if table value was not 2
L1073: JRE     L10C2			; otherwise table value was 2, so jump
L1075: DCR     A
L1076: MOV     B,A
L1077: LXI     H,$FFCC
L107A: MOV     A,D
L107B: SLR     A
L107D: STAX    H+B
L107E: RET
;
; # routine when value from table @ L10E0 is 1
;     
L107F: MOV     A,D
L1080: SLR     A
L1082: ANI     A,$3F
L1084: MOV     C,A
L1085: LDAW    $CC			; $FFCC
L1087: ANI     A,$C0
L1089: ORA     A,C
L108B: STAW    $CC			; $FFCC
L108D: RET 
;
;
;    
L108E: MOV     A,D
L108F: LTI     A,$60
L1091: JR      L1097
L1092: LTI     A,$40
L1094: JR      L1099
L1095: MVI     A,$00
L1097: MVI     A,$80
L1099: MVI     A,$40
L109B: MOV     C,A
L109C: LDAW    $CC			; $FFCC
L109E: ANI     A,$3F
L10A0: ORA     A,C
L10A2: STAW    $CC			; $FFCC
L10A4: RET
;
;
;    
L10A5: MOV     A,D
L10A6: ANI     A,$60
L10A8: BIT     7,$CD
L10AA: ORI     A,$80
L10AC: MOV     PA,A
L10AE: RET
;
;
;     
L10AF: ANI     PA,$7F
L10B2: ONI     D,$10
L10B5: ORI     PA,$80
L10B8: ANIW    $CD,$7F
L10BB: OFFI    D,$10
L10BE: ORIW    $CD,$80
L10C1: RET
;
;
;   
L10C2: MOV     A,D
L10C3: SLR     A
L10C5: ONI     PA,$80
L10C8: ORI     A,$80
L10CA: STAW    $CD			; $FFCD
L10CC: RET
;
;
;    
L10CD: ANI     PA,$7F
L10D0: ONI     D,$40
L10D3: ORI     PA,$80
L10D6: ANIW    $CD,$7F
L10D9: OFFI    D,$40
L10DC: ORIW    $CD,$80
L10DF: RET
;
; # DATA TABLE REFERENCED @ L105A
;   
L10E0: 
	DB $00,$00,$00,$0A,$00,$01,$02,$03
	DB $00,$04,$05,$06,$07,$09,$08,$00
	DB $0B,$00,$00,$00,$00,$00,$00,$00
;
;
;    
L10F8: LDAW    $E7
L10FA: MOV     D,A
L10FB: PUSH    B
L10FC: EQI     B,$04
L10FF: JR      L1111
L1100: MOV     A,D
L1101: LXI     EA,$0000
L1104: MOV     EAL,A
L1105: DSLL    EA
L1107: DSLL    EA
L1109: DSLL    EA
L110B: MOV     A,EAH
L110C: MOV     D,A
L110D: MVI     B,$10
L110F: JRE     L1137
;
;
;
L1111: EQI     B,$0F
L1114: JR      L111B
L1115: MOV     A,D
L1116: CALL    L11E8
L1119: JRE     L1154
;
;
;
L111B: EQI     B,$10
L111E: JR      L1125
L111F: MOV     A,D
L1120: CALL    L11BF
L1123: JRE     L1154
;
;
;
L1125: EQI     B,$11
L1128: JR      L112F
L1129: MOV     A,D
L112A: CALL    L11CB
L112D: JRE     L1154
;
;
;
L112F: PUSH    H				; save HL on stack
L1130: LXI     H,L000B			; mini table
L1133: LDAX    H+B				; get value from table
L1134: POP     H				; get HL from stack
L1135: MOV     B,A
L1136: MOV     A,D
L1137: STAX    H+B
L1138: MOV     A,C
L1139: ORA     A,B
L113B: PUSH    B
L113C: CALF    L0B36
L113E: MOV     A,D
L113F: CALF    L0B36
L1141: POP     B
L1142: BIT     5,$0B
L1144: JR      L1152
L1145: EQI     C,$C0
L1148: JR      L1152
L1149: MVI     A,$A0
L114B: ORA     A,B
L114D: CALF    L0B36
L114F: MOV     A,D
L1150: CALF    L0B36
L1152: POP     B
L1153: RET
;
;
;     
L1154: POP     B
L1155: PUSH    B
L1156: LDAX    H+
L1157: MOV     D,A
L1158: LDAX    H
L1159: MOV     E,A
L115A: MOV     A,C
L115B: CALF    L0B36
L115D: MOV     A,D
L115E: CALF    L0B36
L1160: MOV     A,E
L1161: CALF    L0B36
L1163: POP     B
L1164: PUSH    B
L1165: BIT     5,$0B
L1167: JR      L1176
L1168: EQI     C,$C0
L116B: JR      L1176
L116C: MVI     A,$A0
L116E: CALF    L0B36
L1170: MOV     A,D
L1171: CALF    L0B36
L1173: MOV     A,E
L1174: CALF    L0B36
L1176: POP     B
L1177: RET
;
;
;     
L1178: MVI     A,$80
L117A: MVI     B,$00
L117C: LXI     D,$FFD4
L117F: OFFAX   D
L1181: JR      L1189
L1182: INR     B
L1183: INX     D
L1184: EQI     B,$12
L1187: JR      L117F
L1188: RET
;
L1189:
	LDAX    D
	ANI     A,$7F
	STAX    D
	STAW    $E7
	RETS
;
; # SysEx related?
;   
L1190: LXI     D,$FFD4
L1193: LDAX    D+$0F
L1195: CALL    L11E8
L1198: LDAX    D+$10
L119A: CALL    L11BF
L119D: LDAX    D+$11
L119F: CALL    L11CB
L11A2: INX     H
L11A3: INX     H
L11A4: MVI     B,$03
L11A6: LDAX    D+
L11A7: STAX    H+
L11A8: DCR     B
L11A9: JR      L11A6
L11AA: LDAX    D+
L11AB: LXI     EA,$0000
L11AE: MOV     EAL,A
L11AF: DSLL    EA
L11B1: DSLL    EA
L11B3: DSLL    EA
L11B5: MOV     A,EAH
L11B6: STAX    H+$0A
L11B8: MVI     B,$09
L11BA: LDAX    D+
L11BB: STAX    H+
L11BC: DCR     B
L11BD: JR      L11BA
L11BE: RET
;
;
;    
L11BF: XRI     A,$1F
L11C1: ANI     A,$3F
L11C3: MOV     B,A
L11C4: LDAX    H
L11C5: ANI     A,$40
L11C7: ORA     A,B
L11C9: STAX    H
L11CA: RET
;
;
;     
L11CB: MOV     C,A
L11CC: ANI     A,$27
L11CE: XRI     A,$07
L11D0: MOV     B,A
L11D1: LDAX    H+$01
L11D3: ANI     A,$58
L11D5: ORA     A,B
L11D7: STAX    H+$01
L11D9: MOV     A,C
L11DA: ANI     A,$10
L11DC: SLL     A
L11DE: SLL     A
L11E0: MOV     B,A
L11E1: LDAX    H
L11E2: ANI     A,$3F
L11E4: ORA     A,B
L11E6: STAX    H
L11E7: RET
;
;
;     
L11E8: SLR     A
L11EA: SLR     A
L11EC: ANI     A,$18
L11EE: MOV     B,A
L11EF: LDAX    H+$01
L11F1: ANI     A,$67
L11F3: ORA     A,B
L11F5: STAX    H+$01
L11F7: RET
;
;
;     
L11F8: ORIW    $97,$08
L11FB: ORIW    $98,$08
L11FE: MVIW    $72,$02
L1201: ORIW    $88,$40
L1204: RET
;
;
;    
L1205: ORIW    $99,$08
L1208: ORIW    $9A,$08
L120B: MVIW    $72,$03
L120E: BIT     5,$0B
L1210: MVIW    $72,$01
L1213: JR      L1201
;
;
;
L1214: ORIW    $9B,$08
L1217: ORIW    $9C,$08
L121A: MVIW    $72,$04
L121D: JR      L1201
;
;
;
L121E: MOV     A,D
L121F: STAW    $96
L1221: PUSH    D
L1222: PUSH    B
L1223: LTI     A,$64
L1225: SUI     A,$64
L1227: CALF    L0A4C
L1229: SBCD    $FF89			; LED related?
L122D: POP     B
L122E: POP     D
L122F: MOV     A,D
L1230: OFFIW   $A6,$04			; $FFA6
L1233: JMP     L1050			; otherwise
L1236: BIT     0,$A6			; $FFA6
L1238: LXI     H,$FFA8
L123B: LXI     H,$FFBA
L123E: LTI     B,$0F
L1241: JR      L125A			; otherwise
L1242: INR     B
L1243: STAX    H+B
L1244: MOV     A,B
L1245: MOV     E,A
L1246: BIT     0,$A6			; $FFA6
L1248: MVI     A,$A0
L124A: MVI     A,$C0
L124C: ORA     A,E
L124E: CALF    L0B88
L1250: BIT     5,$0B			; $FF0B
L1252: RET  					; otherwise return   
L1253: MVI     A,$A0
L1255: ORA     A,E
L1257: CALF    L0B88
L1259: RET     
L125A: NEI     B,$10
L125D: RET     
L125E: EQI     B,$0F
L1261: JR      L1274
L1262: LXI     EA,$0000
L1265: MOV     EAL,A
L1266: DSLL    EA
L1268: DSLL    EA
L126A: DSLL    EA
L126C: MOV     A,EAH
L126D: STAX    H+$10
L126F: MOV     D,A
L1270: MVI     E,$10
L1272: JRE     L1246
;
;
;
L1274: MOV     A,B
L1275: MVI     E,$00
L1277: SUI     A,$11
L1279: SLL     A
L127B: TABLE   
L127D: JB  
;
; # JUMP TABLE
;
L127E: 
	DW L1292 
	DW L12CA 
	DW L12CD 
	DW L12D0 
	DW L12AE 
	DW L12D3 
	DW L12D6 
	DW L12D9 
	DW L12DC 
	DW L12DF
;
;
;
L1292: MOV     A,D
L1293: GTI     A,$20
L1295: JR      L129B
L1296: GTI     A,$60
L1298: JR      L129D
L1299: MVI     A,$03
L129B: MVI     A,$06
L129D: MVI     A,$05
L129F: MOV     B,A
L12A0: XRAX    H
L12A2: ONI     A,$07
L12A4: RET     
L12A5: LDAX    H
L12A6: ANI     A,$F8
L12A8: ORA     A,B
L12AA: STAX    H
L12AB: MOV     D,A
L12AC: JRE     L1246
L12AE: MOV     A,D
L12AF: INX     H
L12B0: ANI     A,$60
L12B2: SLR     A
L12B4: SLR     A
L12B6: MOV     B,A
L12B7: LDAX    H
L12B8: ANI     A,$18
L12BA: XRA     A,B
L12BC: NEI     A,$00
L12BE: RET     
L12BF: LDAX    H
L12C0: ANI     A,$E7
L12C2: ORA     A,B
L12C4: STAX    H
L12C5: MVI     E,$01
L12C7: MOV     D,A
L12C8: JRE     L1246
L12CA: MVI     B,$01
L12CC: JR      L12E1
L12CD: MVI     B,$08
L12CF: JR      L12E4
L12D0: MVI     B,$10
L12D2: JR      L12E4
L12D3: MVI     B,$40
L12D5: JR      L12E4
L12D6: MVI     B,$02
L12D8: JR      L12E1
L12D9: MVI     B,$04
L12DB: JR      L12E1
L12DC: MVI     B,$20
L12DE: JR      L12E4
L12DF: MVI     B,$20
L12E1: INX     H
L12E2: MVI     E,$01
L12E4: LDAX    H
L12E5: ANA     A,B
L12E7: EQI     A,$00
L12E9: JR      L12F3
L12EA: BIT     6,$96
L12EC: RET     
L12ED: LDAX    H
L12EE: ORA     A,B
L12F0: STAX    H
L12F1: JRE     L12C7
;
;
;
L12F3: OFFIW   $96,$40
L12F6: RET     
L12F7: XRI     B,$FF
L12FA: LDAX    H
L12FB: ANA     A,B
L12FD: STAX    H
L12FE: JRE     L12C7
;
;
;
L1300: ORIW    $0B,$20
L1303: ONIW    $93,$1C
L1306: MVIW    $8C,$03
L1309: MVIW    $72,$03
L130C: JR      L1319
;
;
;
L130D: ANIW    $0B,$DF
L1310: ONIW    $93,$1C
L1313: MVIW    $8C,$02
L1316: MVIW    $72,$02
L1319: CALF    L0A69
L131B: CALF    L0F47
L131D: ORI     PC,$04
L1320: MVI     A,$80
L1322: CALF    L0E92
L1324: MVI     A,$9F
L1326: CALF    L0B36
L1328: BIT     5,$0B
L132A: MVI     A,$00
L132C: MVI     A,$01
L132E: CALF    L0B36
L1330: LXI     D,$FFBA
L1333: BIT     5,$0B
L1335: LXI     D,$FFA8
L1338: CALF    L0B64
L133A: ORIW    $88,$40
L133D: ANIW    $93,$3E
L1340: MVIW    $E9,$00
L1343: RET
;
; # TEST MODE, very likely
;     
L1344: STAW    $8F
L1346: LXI     B,$F557
L1349: SBCD    $FF97
L134D: EI
;
; fall-through, or entry in jump table @ L1471
;     
L134E: ORI     PC,$08
L1351: ANI     PC,$8F
L1354: LDAW    $D1			; $FFD1
L1356: MOV     ($2800),A
L135A: ANI     PC,$F7
L135D: LBCD    $FF8D
L1361: LXI     H,$FF8F
L1364: LDAX    H+B
L1365: MOV     D,A
L1366: MOV     A,C
L1367: XRA     D,A
L1369: EQI     D,$00
L136C: JRE     L13F6		; otherwise
; fall-through or jumped to
L136E: LDAW    $D2			; $FFD2
L1370: CALF    L09FE
L1372: EQIW    $A7,$FF		; $FFA7
L1375: JR      L138C		; otherwise
L1376: NEIW    $89,$00		; $FF89
L1379: JR      L1381		; otherwise
L137A: LXI     B,$0000
L137D: MVIW    $A7,$20
L1380: JR      L1388
;
;
;
L1381: LBCD    $FF97
L1385: MVIW    $A7,$30		; $FFA7
L1388: SBCD    $FF89		; LED related?
L138C: LDAW    $D0			; load $FFD0
L138E: CALF    L09FE
L1390: MOV     A,CR0		; capture master tune value?
L1392: LXI     H,$FFA0
L1395: CALF    L0A11		; process A/D value
L1397: LDAW    $D3			; load $FFD3 -- can be skipped by RETS
L1399: CALF    L09FE
L139B: MOV     A,CR1		; capture bass detune value?
L139D: LXI     H,$FFA1
L13A0: CALF    L0A11		; process A/D value
L13A2: MOV     A,CR2		; can be skipped by RETS -- capture dynamic sense value?
L13A4: STAW    $A2			; $FFA2 -- dynamic sense value?
L13A6: LDAW    $CD
L13A8: CALF    L09FE
L13AA: BIT     7,$E7		; $FFE7
L13AC: JRE     L13D7		; otherwise
L13AE: LDAW    $01			; $FF01
L13B0: XRAW    $8E			; $FF8E
L13B3: NEI     A,$00
L13B5: JRE     L13D7		; otherwise
L13B7: LDAW    $8E			; $FF8E
L13B9: STAW    $01			; $FF01
L13BB: EQI     A,$00
L13BD: JR      L13D7		; otherwise
L13BE: INRW    $02			; $FF02
L13C0: BIT     0,$02		; $FF02
L13C2: JR      L13CD		; otherwise
L13C3: BIT     2,$00		; $FF00
L13C5: JR      L13C9		; otherwise
L13C6: CALF    L0D0F
L13C8: JR      L13D7
;
;
;
L13C9: CALL    L16C1
L13CC: JR      L13D7
;
;
;
L13CD: BIT     2,$00		; $FF00
L13CF: JR      L13D3		; otherwise
L13D0: CALF    L0E23
L13D2: JR      L13D7
;
;
;
L13D3: MVI     A,$80
L13D5: CALF    L0E92
L13D7: LDAW    $9F			; $FF9F
L13D9: CALF    L09FE
L13DB: BIT     6,$E7		; $FFE7
L13DD: JR      L13E8		; otherwise
L13DE: BIT     4,$91		; $FF91
L13E0: JR      L13E5		; otherwise
L13E1: ANI     PC,$FB
L13E4: JR      L13E8
;
;
;
L13E5: ORI     PC,$04
L13E8: LDAW    $A4			; $FFA4
L13EA: CALF    L09FE
L13EC: DIV     A
L13EE: LDAW    $CC			; $FFCC
L13F0: CALF    L09FE
L13F2: DIV     A
L13F4: JRE     L134E
;
;
;
L13F6: STAX    H+B
L13F7: ANA     A,D
L13F9: NEI     A,$00
L13FB: JRE     L136E		; otherwise
L13FD: EQI     B,$03
L1400: JR      L1405		; otherwise
L1401: STAW    $00			; $FF00
L1403: JRE     L1427
;
;
;
L1405: OFFI    A,$10
L1407: JMP     L1555		; goes to a jump table
L140A: ONI     A,$08
L140C: JR      L1418		; otherwise
L140D: NEI     B,$00
L1410: JRE     L1499		; otherwise
L1412: NEI     B,$01
L1415: JR      L1427		; otherwise
L1416: JRE     L149C
;
;
;
L1418: OFFI    A,$04
L141A: JR      L1422		; otherwise
L141B: OFFI    A,$02
L141D: JR      L1420		; otherwise
L141E: MVI     A,$03
L1420: MVI     A,$06
L1422: MVI     A,$09
L1424: SUB     A,B
L1426: JR      L1429
L1427: MVI     A,$00
L1429: STAW    $E7			; $FFE7
L142B: CALF    L0E29
L142D: MVI     A,$80
L142F: CALF    L0E92
L1431: CALF    L0F35
L1433: MVI     A,$9C
L1435: CALF    L0B36
L1437: CALF    L0B36
L1439: NEIW    $00,$08		; $FF00
L143C: JMP     L16A0		; otherwise
L143F: NEIW    $00,$04		; $FF00
L1442: JMP     L15FD		; otherwise
L1445: MVI     B,$0F
L1447: DIV     A
L1449: DCR     C
L144A: JR      L1447		; otherwise
L144B: DCR     B
L144C: JR      L1447		; otherwise
L144D: LDAW    $E7			; $FFE7
L144F: CALF    L0A0C
L1451: STAW    $98			; $FF98
L1453: EQIW    $00,$02		; $FF00
L1456: MVI     A,$10
L1458: MVI     A,$44
L145A: STAW    $97			; $FF97
L145C: MVIW    $E8,$00		; $FFE8
L145F: MVIW    $03,$00		; $FF03
L1462: EQIW    $00,$02		; $FF00
L1465: MVI     A,$00
L1467: MVI     A,$0A
L1469: ADDW    $E7
L146C: SLL     A
L146E: TABLE   
L1470: JB
;
; # JUMP TABLE
;     
L1471: 
	DW L14A3
	DW L14B4
	DW L14C0
	DW L14CC
	DW L14D5
	DW L14E4
	DW L14E4
	DW L14D5
	DW L14F7
	DW L14F7
	DW L1504
	DW L1515
	DW L1515
	DW L152F
	DW L152F
	DW L1538
	DW L1538
	DW L134E
	DW L134E
	DW L134E
;
;
;
L1499: MVI     A,$0A
L149B: JR      L149E
;
;
;
L149C: MVI     A,$0B
L149E: STAW    $E7			; $FFE7
L14A0: JMP     L16A0
;
; entry in jump table @ L1471
;
L14A3: MVI     A,$9D
L14A5: CALF    L0B36
L14A7: CALF    L0B36
L14A9: MVI     A,$9C
L14AB: CALF    L0B36
L14AD: MVI     A,$00
L14AF: CALF    L0B36
L14B1: JMP     L136E
;
; entry in jump table @ L1471
;
L14B4: MVI     A,$64
L14B6: CALL    L16D6
L14B9: MVIW    $81,$3C		; $FF81
L14BC: ORIW    $E7,$80		; $FFE7
L14BF: JR      L14B1
;
; entry in jump table @ L1471
;
L14C0: MVI     A,$65
L14C2: CALL    L16D6
L14C5: MVIW    $81,$3C		; $FF81
L14C8: CALL    L16C1
L14CB: JR      L14B1
;
; entry in jump table @ L1471
;
L14CC: MVI     A,$65
L14CE: CALL    L16D6
L14D1: MVIW    $81,$54		; $FF81
L14D4: JR      L14C8
;
; entry in jump table @ L1471
;
L14D5: MVI     A,$67
L14D7: CALL    L16D6
L14DA: MVIW    $03,$01		; $FF03
L14DD: EQIW    $E7,$04		; $FFE7
L14E0: MVIW    $03,$03		; $FF03
L14E3: JR      L14C5
;
; entry in jump table @ L1471
;
L14E4: MVI     A,$6A
L14E6: CALL    L16D6
L14E9: MVIW    $95,$6E		; $FF95
L14EC: MVIW    $03,$02		; $FF03
L14EF: EQIW    $E7,$05		; $FFE7
L14F2: MVIW    $03,$03		; $FF03
L14F5: JRE     L14C5
;
; entry in jump table @ L1471
;
L14F7: MVI     A,$66
L14F9: CALL    L16D6
L14FC: MVIW    $95,$06		; $FF95
L14FF: MVIW    $03,$04		; $FF03
L1502: JRE     L14C5
;
; entry in jump table @ L1471
;
L1504: MVI     A,$6A
L1506: MVIW    $03,$05		; $FF03
L1509: CALL    L16D6
L150C: MVIW    $81,$3C		; $FF81
L150F: CALL    L16F9
L1512: JMP     L136E
;
; entry in jump table @ L1471
;
L1515: MVI     A,$67
L1517: CALL    L16D6
L151A: EQIW    $E7,$02		; $FFE7
L151D: JR      L152A		; otherwise
L151E: LXI     D,$0701
L1521: CALL    L16E6
L1524: LXI     D,$6505
L1527: CALL    L16E6
L152A: MVIW    $03,$05		; $FF03
L152D: JRE     L150C
;
; entry in jump table @ L1471
;
L152F: EQIW    $E7,$03		; $FFE7
L1532: MVI     A,$6B
L1534: MVI     A,$6C
L1536: JRE     L1506
;
; entry in jump table @ L1471
;
L1538: EQIW    $E7,$05		; $FFE7
L153B: MVI     A,$20
L153D: MVI     A,$40
L153F: STAW    $E9			; $FFE9
L1541: MVIW    $03,$06		; $FF03
L1544: MVIW    $02,$00		; $FF02
L1547: MVI     A,$67
L1549: CALL    L16D6
L154C: MVIW    $81,$24		; $FF81
L154F: CALL    L16F9
L1552: JMP     L136E
;
;
;
L1555: OFFIW   $00,$0C		; $FF00
L1558: JR      L1560		; otherwise jump
L1559: LDAW    $03			; $FF03
L155B: NEI     A,$00		; skip next if not equal to zero
L155D: JR      L1560		; otherwise zero so jump
L155E: LTI     A,$07		; skip next if less than 7 (since there are only 6 table values)
L1560: JRE     L1582		; otherwise value was 7 or more, so jump
L1562: DCR     A			; decrement to account for zero index
L1563: SLL     A			; double the index because table values are 16-bit
L1565: TABLE   
L1567: JB
;
; # JUMP TABLE
;     
L1568:
	DW L1574
	DW L1585
	DW L159D
	DW L15B6
	DW L15CD
	DW L15D9
;
; entry in jump table @ L1568
;
L1574: 
	INRW    $95				; $FF95
	NOP						; negates potential skip
	LXI     D,$0005
	BIT     0,$95			; $FF95
	LXI     D,$6505			; otherwise
L157F:
	CALL    L16E6
L1582:
	JMP     L136E
;
; entry in jump table @ L1568
;
L1585: LDAW    $95			; $FF95
L1587: MOV     B,A
L1588: ANI     B,$F8
L158B: STC     
L158D: RLL     A
L158F: ONI     A,$08
L1591: MVI     A,$06
L1593: ANI     A,$07
L1595: ORA     A,B
L1597: STAW    $95			; $FF95
L1599: MOV     D,A
L159A: MVI     E,$00
L159C: JR      L157F
;
; entry in jump table @ L1568
;
L159D: LDAW    $95				; $FF95
L159F: INR     A
L15A0: ANI     A,$03
L15A2: STAW    $95				; $FF95
L15A4: NEI     A,$03
L15A6: JR      L15AD			; otherwise
L15A7: NEI     A,$01
L15A9: MVI     A,$24			; otherwise
L15AB: MVI     A,$3C
L15AD: MVI     A,$60
L15AF: STAW    $81				; $FF81
L15B1: CALL    L16C1
L15B4: JRE     L1582
;
; entry in jump table @ L1568
;
L15B6: LDAW    $95				; $FF95
L15B8: EQIW    $E7,$08			; $FFE7
L15BB: JR      L15C1			; otherwise
L15BC: ADI     A,$08
L15BE: ANI     A,$1F
L15C0: JR      L15C3
;
;
;
L15C1: XRI     A,$20
L15C3: STAW    $95				; $FF95
L15C5: MOV     D,A
L15C6: MVI     E,$01
L15C8: CALL    L16E6
L15CB: JRE     L1582
;
; entry in jump table @ L1568
;
L15CD: MVI     A,$80
L15CF: CALF    L0E92
L15D1: CALL    L1709
L15D4: CALL    L16F9
L15D7: JRE     L1582
;
; entry in jump table @ L1568
;
L15D9: BIT     0,$02		; $FF02
L15DB: JR      L15E3		; otherwise
L15DC: MVI     A,$80
L15DE: CALF    L0E92
L15E0: CALL    L1709
L15E3: LTIW    $E8,$02		; $FFE8
L15E6: MVI     A,$C0
L15E8: MVI     A,$A0
L15EA: CALF    L0B36
L15EC: LDAW    $A8			; $FFA8
L15EE: XRAW    $E9			; $FFE9
L15F1: STAW    $A8			; $FFA8
L15F3: CALF    L0B36
L15F5: CALL    L16F9
L15F8: INRW    $02			; $FF02
L15FA: NOP					; negates potential skip     
L15FB: JRE     L1582
;
;
;
L15FD: MVIW    $98,$37		; $FF98
L1600: LDAW    $E7			; $FFE7
L1602: LTI     A,$09		; skip next if less than 9
L1604: JRE     L1630		; otherwise 
L1606: CALF    L0A0C
L1608: STAW    $97			; $FF97
L160A: MVIW    $81,$18		; $FF81
L160D: LDAW    $E7			; $FFE7
L160F: SLL     A
L1611: TABLE   
L1613: JB
;
; # JUMP TABLE -- 9 ENTRIES
;     
L1614:
	DW L1626
	DW L1633
	DW L163A
	DW L163A
	DW L164B
	DW L164B
	DW L165D
	DW L1669
	DW L1669 
;
; entry in jump table @ L1614
;
L1626: ORIW    $E7,$80				; $FFE7
L1629: LXI     H,L167C				; data table
L162C: CALF    L09E7
L162E: CALF    L0D0F
L1630: JMP     L136E
;
; entry in jump table @ L1614
;
L1633: LXI     H,L1685				; data table
L1636: ORIW    $E7,$40				; $FFE7
L1639: JR      L162C
;
; entry in jump table @ L1614
;
L163A: LXI     H,L168E				; data table
L163D: CALF    L09E7
L163F: NEIW    $E7,$03				; $FFE7
L1642: MVIW    $CC,$3F				; $FFCC
L1645: CALF    L0D0F
L1647: MVI     EOM,$00
L164A: JR      L1630
;
; entry in jump table @ L1614
;
L164B: LXI     H,L168E				; data table
L164E: CALF    L09E7
L1650: MVIW    $CE,$3F				; $FFCE
L1653: EQIW    $E7,$04				; $FFE7
L1656: MVI     A,$7F
L1658: MVI     A,$40
L165A: STAW    $82					; $FF82
L165C: JR      L1645
;
; entry in jump table @ L1614
;
L165D: LXI     H,L1697				; data table
L1660: CALF    L09E7
L1662: MVIW    $81,$30				; $FF81
L1665: CALF    L0D0F
L1667: JRE     L1630
;
; entry in jump table @ L1614
;
L1669: LXI     H,L168E				; data table
L166C: CALF    L09E7
L166E: MVIW    $CC,$10				; $FFCC
L1671: EQIW    $E7,$07				; $FFE7
L1674: MVI     A,$30
L1676: MVI     A,$24
L1678: STAW    $81					; $FF81
L167A: JRE     L1645
;
; # DATA TABLE USED BY L1629
;
L167C:

	DB $00,$00,$00,$00,$3F,$00,$00,$00,$00
;
; # DATA TABLE USED BY L1633
;
L1685:	
	DB $3F,$00,$00,$3F,$3F,$3F,$00,$00,$00
;
; # DATA TABLE USED BY L163A AND OTHERS
;
L168E:	
	DB $00,$3F,$00,$3F,$3F,$00,$00,$3F,$00
;
; # DATA TABLE USED BY 165D
;
L1697:	
	DB $3F,$00,$00,$3F,$3F,$00,$00,$3F,$00
;
;
;
L16A0:
	LXI     B,$5711
	SBCD    $FF97
	LDAW    $A2				; $FFA2 -- dynamic sense value?
	SLR     A
	MOV     C,A
	LDAW    $E7				; $FFE7
	CALF    L0F8D
	ANIW    $8B,$F7			; $FF8B
	JRE     L1630
;
; data table referenced @ L0F8D
;
L16B5:
	DB $33,$24,$28,$2B,$2F,$32,$25,$27,$2C,$2E,$31,$31
;
;
;	
L16C1:
	MVI     B,$05
L16C3:
	MVI     A,$90
	ORA     A,B
	PUSH    B
	CALF    L0B36
	LDAW    $81			; $FF81
	CALF    L0B36
	MVI     A,$7F
	CALF    L0B36
	POP     B
	DCR     B
	JR      L16C3		; otherwise
	RET
	
L16D6:
	LXI     H,$FFA8
	CALF    L0B52
	LXI     D,$FFA8
	CALF    L0B66
	LXI     D,$FFA8
	CALF    L0B64
	RET

L16E6:
	MVI     A,$A0
	ORA     A,E
	CALF    L0B36
	MOV     A,D
	CALF    L0B36
	MVI     A,$C0
	ORA     A,E
	CALF    L0B36
	MOV     A,D
	CALF    L0B36
	RET
	
L16F9:
	MVI     A,$90
	ORAW    $E8			; $FFE8
	CALF    L0B36
	LDAW    $81			; $FF81
	CALF    L0B36
	MVI     A,$7F
	CALF    L0B36
	RET
	
L1709:	
	LDAW    $E8			; $FFE8
	INR     A
	LTI     A,$06
	MVI     A,$00
	STAW    $E8			; $FFE8
	INR     A
	CALF    L0A0C
	STAW    $97			; $FF97
	RET     

L1718:
;
; # SCALING DATA OF SOME SORT? HOW IS THIS LOADED OR REACHED?
;
	DB $01,$02,$04,$08,$10,$20
	DB $FE,$FD,$FB,$F7,$EF,$DF
	
L1724:
;
; # UNKNOWN DATA REFERENCED @ L0A0C
;	
	DB $E7,$44,$D3,$D6,$74,$B6,$B7,$E4,$F7,$F6
;
; # UNKNOWN DATA REFERENCED @ L0ED2 -- at least the first 16 or 17 appear to be two-byte words
;	
L172E:	
	DB $FE,$3B,$FE,$3B,$BF,$3B,$FD,$3B,$7F,$3B,$FD,$3B,$FB,$3B,$DF,$3B
	DB $FB,$3B,$DF,$3B,$F7,$3B,$DF,$3B,$F7,$3B,$EF,$3B,$FF,$3A,$EF,$3B
;
; # TONE COLORS FOR MELODY, CHORD, AND BASS BLOCKS ARE PROBABLY IN HERE 
;
	DB $FF,$39,$6E,$F0,$E9,$E2,$1F,$D6,$18,$CA,$BA,$BE,$04,$B4
	DB $E0,$A9,$52,$A0,$4F,$97,$CC,$8E,$C5,$86,$33,$7F,$0F,$78,$51,$71 
	DB $EF,$6A,$EE,$64,$42,$5F,$E9,$59,$D9,$54,$15,$50,$95,$4B,$54,$47
	DB $53,$43,$8D,$3F,$FC,$3B,$9E,$38,$6E,$35,$6E,$32,$99,$2F,$ED,$2C
	DB $66,$2A,$05,$28,$C5,$25,$A5,$23,$A5,$21,$C3,$1F,$FB,$1D,$4C,$1C 
	DB $B4,$1A,$34,$19,$CA,$17,$74,$16,$31,$15,$01,$14,$E1,$12,$D1,$11
	DB $D1,$10,$E1,$0F,$FD,$0E,$25,$0E,$59,$0D,$99,$0C,$E4,$0B,$39,$0B
	DB $98,$0A,$00,$0A,$70,$09,$E8,$08,$68,$08,$F0,$07,$7E,$07,$12,$07 
	DB $AC,$06,$4C,$06,$F2,$05,$9C,$05,$4C,$05,$00,$05,$B8,$04,$74,$04
	DB $34,$04,$F8,$03,$BF,$03,$89,$03,$56,$03,$26,$03,$F9,$02,$CE,$02
	DB $A6,$02,$80,$02,$5C,$02,$3A,$02,$1A,$02,$FC,$01,$DF,$01,$C4,$01 
	DB $AB,$01,$00,$00,$65,$06,$4F,$1C,$00,$51,$39,$00,$20,$00,$44,$30
	DB $00,$3A,$16,$0F,$03,$65,$06,$4F,$00,$00,$0B,$35,$26,$14,$00,$4D
	DB $33,$00,$2F,$1C,$0F,$03,$63,$0E,$4F,$00,$00,$0B,$33,$2A,$0E,$04 
	DB $55,$34,$00,$42,$1C,$34,$03,$55,$06,$56,$22,$00,$09,$38,$10,$04
	DB $14,$4A,$56,$00,$21,$0C,$36,$03,$73,$0E,$4F,$00,$00,$42,$7F,$57
	DB $7F,$00,$69,$40,$00,$1F,$17,$10,$03,$45,$06,$48,$1C,$00,$51,$3E 
	DB $00,$16,$00,$1E,$30,$00,$3A,$16,$0F,$03,$45,$07,$3D,$00,$00,$36
	DB $5C,$00,$14,$00,$3C,$19,$00,$2F,$0D,$0F,$03,$73,$1E,$4F,$2A,$00
	DB $21,$30,$00,$44,$00,$57,$1A,$00,$31,$2A,$43,$03,$55,$07,$22,$00 
	DB $00,$52,$38,$26,$14,$00,$3C,$38,$00,$2F,$1C,$0F,$03,$35,$06,$4F
	DB $00,$00,$50,$29,$00,$48,$00,$3C,$36,$00,$46,$0F,$00,$01,$6D,$03
	DB $5C,$00,$00,$00,$2D,$00,$5E,$00,$7F,$27,$03,$2C,$6B,$0B,$03,$6E 
	DB $02,$43,$00,$00,$42,$1C,$00,$7F,$00,$7F,$20,$04,$2A,$3F,$06,$03
	DB $6D,$06,$3F,$00,$00,$0B,$37,$00,$35,$00,$6F,$31,$07,$2D,$38,$11
	DB $03,$75,$02,$4F,$00,$00,$64,$1D,$0D,$7F,$00,$7F,$34,$03,$0D,$6C 
	DB $06,$03,$65,$02,$4F,$26,$07,$00,$10,$33,$7F,$00,$7F,$27,$03,$1B
	DB $57,$06,$03,$4D,$06,$4F,$00,$00,$0B,$2C,$00,$7F,$00,$7F,$33,$01
	DB $1F,$60,$0B,$03,$55,$06,$5D,$00,$00,$49,$26,$00,$56,$00,$7F,$2B 
	DB $03,$2B,$70,$0B,$03,$4D,$06,$3F,$00,$00,$0B,$2C,$00,$35,$00,$6F
	DB $43,$07,$2D,$38,$11,$03,$4E,$06,$3F,$00,$00,$0B,$2C,$00,$35,$00
	DB $6F,$43,$07,$2D,$38,$11,$03,$75,$07,$3E,$00,$06,$5B,$0A,$2D,$5A 
	DB $00,$7F,$28,$05,$10,$71,$19,$01,$6D,$06,$50,$1D,$0A,$0B,$4E,$00
	DB $00,$00,$44,$3D,$26,$45,$55,$19,$03,$6D,$06,$52,$00,$00,$0B,$53
	DB $00,$00,$00,$44,$35,$06,$0B,$61,$10,$03,$6D,$06,$48,$1A,$0A,$0B 
	DB $4A,$00,$00,$00,$13,$57,$00,$0C,$00,$20,$03,$6E,$07,$48,$31,$0F
	DB $00,$4D,$0F,$00,$00,$78,$3C,$25,$2D,$39,$1A,$03,$6D,$06,$48,$1A
	DB $0A,$67,$4D,$6B,$00,$00,$5F,$29,$07,$45,$22,$10,$03,$45,$07,$30 
	DB $00,$00,$56,$4F,$00,$00,$00,$59,$19,$20,$45,$55,$26,$03,$45,$07
	DB $39,$2D,$00,$37,$56,$00,$00,$00,$6C,$10,$03,$3B,$70,$1A,$01,$53
	DB $1F,$42,$2A,$00,$21,$32,$00,$44,$00,$7F,$10,$00,$31,$2A,$43,$03
	DB $46,$07,$30,$00,$0C,$56,$54,$00,$00,$00,$59,$0E,$1C,$0F,$7F,$16
	DB $03,$43,$07,$55,$00,$04,$56,$62,$00,$00,$00,$59,$04,$06,$0F,$7F
	DB $23,$03,$63,$06,$5D,$00,$00,$1B,$4A,$00,$00,$12,$3E,$33,$03,$23 
	DB $5E,$0B,$03,$35,$06,$45,$16,$09,$00,$23,$00,$31,$07,$62,$5C,$05
	DB $7F,$6A,$07,$03,$35,$06,$54,$20,$19,$58,$51,$00,$08,$00,$70,$3B
	DB $03,$01,$6F,$08,$03,$75,$06,$4D,$00,$00,$32,$40,$00,$28,$00,$70 
	DB $36,$01,$0F,$7B,$02,$03,$76,$07,$0C,$00,$00,$65,$16,$01,$7F,$00
	DB $52,$30,$03,$1C,$70,$02,$03,$75,$06,$55,$00,$00,$66,$0C,$61,$7F
	DB $00,$52,$34,$03,$1C,$78,$02,$03,$43,$07,$57,$0D,$05,$48,$4A,$00 
	DB $00,$0F,$3E,$33,$04,$0E,$6F,$0D,$03,$55,$07,$3F,$00,$00,$0A,$35
	DB $00,$28,$00,$70,$37,$01,$0F,$7B,$02,$03,$46,$07,$0C,$00,$00,$65
	DB $16,$01,$7F,$00,$52,$25,$03,$1C,$70,$02,$03,$43,$1F,$51,$0B,$00 
	DB $54,$3A,$00,$25,$00,$7F,$1D,$02,$1E,$7F,$13,$03,$55,$1A,$4F,$2A
	DB $00,$49,$3C,$48,$0E,$00,$7F,$20,$00,$00,$00,$00,$03,$53,$1A,$4F
	DB $2A,$00,$49,$38,$6E,$03,$00,$7F,$20,$00,$00,$00,$00,$03,$53,$1E 
	DB $4F,$2A,$00,$67,$42,$58,$00,$00,$7F,$27,$00,$1A,$45,$00,$03,$55
	DB $02,$4F,$2A,$00,$1A,$33,$00,$00,$00,$6D,$50,$00,$00,$4E,$00,$03
	DB $45,$1E,$4F,$2A,$00,$38,$42,$0F,$00,$00,$45,$1D,$06,$1A,$7F,$1E 
	DB $01,$56,$07,$48,$2D,$1C,$67,$1F,$4F,$32,$00,$71,$30,$0A,$46,$78
	DB $23,$02,$53,$07,$62,$2D,$14,$4A,$20,$61,$4B,$00,$71,$3F,$03,$15
	DB $7F,$13,$03,$45,$07,$1B,$00,$00,$55,$23,$00,$51,$00,$47,$21,$00 
	DB $2F,$53,$00,$03,$05,$16,$5F,$00,$00,$40,$4D,$00,$0E,$00,$4A,$2A
	DB $08,$03,$6E,$09,$03,$73,$07,$60,$18,$00,$04,$49,$45,$00,$00,$6B
	DB $30,$02,$17,$7F,$0A,$03,$75,$07,$23,$00,$00,$66,$1B,$33,$7F,$00 
	DB $28,$36,$00,$4D,$60,$00,$03,$53,$07,$55,$00,$00,$00,$3A,$00,$5A
	DB $00,$1A,$30,$00,$03,$7F,$00,$03,$75,$06,$5D,$00,$00,$00,$40,$00
	DB $22,$00,$7F,$38,$00,$00,$7F,$00,$03,$55,$08,$4E,$00,$00,$51,$3D 
	DB $65,$2E,$00,$7F,$40,$00,$00,$00,$00,$03,$45,$00,$4D,$00,$00,$00
	DB $5C,$00,$7F,$00,$6C,$25,$0C,$00,$28,$00,$03,$46,$01,$1E,$00,$00
	DB $67,$6F,$16,$40,$00,$6C,$28,$07,$0B,$4E,$00,$03,$53,$01,$35,$2D 
	DB $00,$66,$70,$34,$3E,$00,$6C,$36,$0D,$0B,$20,$00,$03,$65,$0E,$47
	DB $00,$00,$52,$16,$4F,$4C,$03,$35,$2C,$00,$2D,$39,$00,$03,$53,$06
	DB $5E,$00,$00,$00,$40,$30,$23,$00,$28,$53,$00,$0B,$3D,$00,$03,$43
	DB $06,$5E,$00,$00,$57,$42,$00,$5A,$00,$7F,$24,$00,$24,$54,$00,$03
	DB $55,$07,$55,$00,$00,$00,$3A,$00,$5A,$00,$1A,$3E,$00,$17,$00,$2A
	DB $03,$55,$06,$5E,$00,$00,$59,$2F,$03,$4C,$00,$25,$3B,$00,$3B,$00
	DB $3D,$03,$45,$07,$00,$00,$00,$51,$33,$45,$5C,$00,$58,$26,$0A,$2B
	DB $00,$2A,$03,$43,$1F,$0E,$2D,$00,$67,$4D,$13,$26,$00,$3A,$2B,$00
	DB $17,$1D,$23,$03,$73,$06,$1C,$00,$00,$00,$21,$18,$36,$00,$26,$40 
	DB $00,$2C,$00,$51,$01,$53,$0E,$58,$00,$00,$2E,$4C,$00,$5A,$00,$7F
	DB $3C,$00,$19,$0F,$2D,$03,$55,$06,$4F,$00,$00,$00,$45,$00,$5A,$00
	DB $7F,$45,$00,$06,$08,$44,$03,$45,$06,$4F,$00,$00,$51,$5C,$00,$14 
	DB $00,$3C,$28,$00,$26,$3D,$2C,$03,$45,$0B,$33,$7F,$00,$49,$14,$38
	DB $7F,$00,$7F,$1E,$03,$52,$33,$0B,$03,$43,$07,$50,$00,$00,$57,$09
	DB $5E,$7F,$00,$7F,$2C,$00,$41,$26,$1D,$01,$45,$06,$50,$00,$00,$32 
	DB $30,$00,$7F,$00,$7F,$24,$06,$1C,$41,$13,$03,$4D,$06,$4F,$00,$00
	DB $2E,$3E,$00,$2D,$00,$39,$38,$06,$27,$5E,$42,$03,$55,$06,$4F,$00
	DB $00,$66,$3D,$40,$32,$00,$39,$42,$0C,$2E,$45,$2F,$03,$55,$06,$46 
	DB $00,$00,$00,$35,$38,$2C,$00,$7F,$30,$04,$41,$20,$2E,$03,$53,$1E
	DB $00,$00,$00,$4B,$37,$71,$38,$2C,$78,$10,$0C,$40,$7F,$2E,$03,$4D
	DB $06,$56,$47,$15,$66,$3C,$1F,$12,$01,$4C,$46,$00,$42,$30,$26,$01 
	DB $45,$06,$44,$30,$0C,$32,$42,$00,$63,$00,$7F,$20,$00,$51,$20,$17
	DB $03,$13,$06,$3B,$00,$00,$32,$3C,$40,$2E,$06,$23,$41,$06,$2E,$2B
	DB $2E,$03,$45,$0F,$55,$00,$00,$42,$33,$55,$7F,$00,$7F,$2C,$1C,$24 
	DB $56,$4B,$03,$55,$06,$55,$00,$00,$63,$52,$40,$28,$00,$7F,$43,$07
	DB $11,$62,$1A,$03,$45,$09,$32,$00,$00,$63,$7F,$00,$7F,$00,$56,$00
	DB $05,$31,$00,$00,$01,$55,$00,$55,$00,$00,$00,$7F,$00,$59,$00,$56 
	DB $00,$05,$00,$32,$3A,$01,$55,$04,$59,$0E,$01,$00,$52,$4C,$7F,$00
	DB $42,$5C,$17,$69,$00,$45,$03,$55,$04,$40,$00,$00,$66,$3E,$6B,$05
	DB $00,$48,$5B,$0A,$32,$0A,$3C,$01,$13,$05,$7F,$00,$00,$66,$7F,$3E 
	DB $75,$4D,$47,$45,$00,$12,$1E,$2C,$03,$13,$05,$7F,$0E,$00,$66,$4A
	DB $7F,$00,$00,$47,$35,$00,$12,$00,$00,$01,$0B,$05,$3A,$0E,$00,$66
	DB $4B,$73,$40,$00,$47,$60,$00,$00,$3E,$28,$01,$13,$07,$3A,$0E,$00 
	DB $66,$46,$7F,$00,$00,$47,$30,$00,$2C,$00,$28,$01,$55,$07,$7F,$00
	DB $00,$25,$36,$7F,$00,$00,$7F,$3B,$00,$12,$1C,$1A,$01,$5D,$07,$7F
	DB $00,$00,$00,$45,$7F,$00,$00,$7F,$38,$00,$12,$1C,$1A,$01,$5D,$07 
	DB $7F,$00,$00,$00,$4D,$7F,$1C,$23,$7F,$34,$00,$4F,$00,$19,$03,$5D
	DB $05,$7F,$00,$00,$00,$50,$7F,$28,$23,$7F,$38,$00,$60,$00,$23,$03
	DB $5D,$07,$7F,$00,$00,$00,$50,$7F,$2D,$00,$7F,$38,$00,$18,$00,$13 
	DB $03,$7D,$27,$69,$00,$00,$00,$2D,$74,$14,$00,$4B,$57,$00,$1F,$00
	DB $1C,$03,$7D,$27,$00,$00,$00,$41,$22,$00,$34,$00,$7F,$59,$00,$1D
	DB $17,$6D,$03,$7D,$27,$00,$00,$00,$41,$24,$00,$46,$00,$7F,$58,$02 
	DB $71,$00,$2E,$03,$3D,$27,$01,$00,$00,$41,$49,$0B,$1B,$25,$33,$58
	DB $68,$69,$4E,$58,$03,$7D,$27,$03,$00,$00,$41,$32,$52,$1B,$0D,$33
	DB $58,$7F,$00,$7F,$3C,$03,$3D,$27,$29,$00,$00,$41,$3F,$00,$35,$00 
	DB $7F,$58,$00,$27,$00,$1A,$03,$7D,$06,$5E,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00,$7D,$06,$40,$00,$00,$00,$7F,$00
	DB $00,$00,$7F,$40,$00,$00,$00,$00,$03,$7D,$06,$40,$00,$00,$00,$31 
	DB $7F,$00,$00,$7F,$40,$00,$00,$7F,$00,$03,$7D,$06,$40,$00,$00,$00
	DB $7F,$00,$00,$00,$7F,$40,$00,$00,$7F,$00,$03,$75,$06,$50,$00,$00
	DB $00,$7F,$00,$00,$00,$7F,$40,$00,$00,$7F,$00,$03,$7D,$02,$40,$00 
	DB $00,$00,$31,$7F,$7F,$00,$7F,$40,$18,$20,$00,$00,$03,$7D,$06,$50
	DB $20,$00,$00,$31,$7F,$00,$7F,$7F,$40,$00,$00,$7F,$00,$03,$6D,$06
	DB $40,$00,$00,$00,$7F,$00,$00,$00,$7F,$40,$00,$00,$7F,$00,$03,$7D 
	DB $06,$40,$00,$00,$00,$00,$7F,$7F,$00,$7F,$40,$00,$00,$7F,$00,$03
	DB $7D,$04,$40,$00,$00,$00,$7F,$7F,$7F,$00,$7F,$40,$00,$00,$7F,$00
	DB $03,$90,$80,$3B,$3F,$1A,$00,$1A,$20,$2F,$00,$80,$3F,$3F,$28,$00 
	DB $25,$20,$22,$19,$8C,$00,$3F,$20,$35,$31,$10,$26,$0A,$8C,$3F,$3F
	DB $20,$2A,$25,$10,$25,$00,$80,$3F,$3F,$20,$00,$34,$20,$2F,$0D,$80
	DB $3F,$3F,$1C,$00,$1E,$20,$2A,$05,$A1,$3F,$3F,$30,$00,$1E,$20,$2A 
	DB $0A,$A8,$3F,$3F,$28,$29,$25,$10,$2A,$0A,$80,$2D,$3F,$32,$00,$12
	DB $20,$00,$08,$80,$3F,$3F,$23,$00,$23,$20,$00,$0E,$80,$3F,$3F,$28
	DB $00,$1E,$10,$00,$56,$01,$20,$12,$30,$00,$26,$10,$00,$97,$0A,$28 
	DB $2F,$3F,$00,$18,$10,$00,$8C,$9F,$28,$2F,$3F,$00,$18,$10,$00,$94
	DB $A6,$28,$2F,$3F,$00,$18,$10,$00,$91,$A6,$1C,$2F,$3F,$25,$18,$10
	DB $00,$56,$18,$20,$12,$3F,$00,$26,$10,$11,$14,$80,$00,$00,$30,$00 
	DB $30,$00,$00,$14,$80,$00,$00,$30,$00,$3F,$00,$22,$14,$A0,$00,$00
	DB $30,$00,$30,$00,$00,$27,$80,$00,$22,$32,$13,$22,$2A,$0C,$29,$80
	DB $00,$22,$3F,$03

