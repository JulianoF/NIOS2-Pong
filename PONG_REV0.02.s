.equ PIXEL_BUFFER_START, 0x08000000
.equ PIXEL_BUFFER_END, 0x0803BE80
.equ CHAR_BUFFER, 0x09000000
.equ SWITCH_BUFFER, 0x10000050

.equ VGA_ROW_VIS_WIDTH, 0x280 /*HEX WIDTH OF BYTES USED FOR ONE FULL ROW OF PIXELS that are visible on screen*/
.equ VGA_HALF_ROW_VIS_WIDTH, 0x140 /*HEX HALF WIDTH OF BYTES USED FOR ONE HALF ROW OF PIXELS that are visible on screen*/

.equ VGA_SIZE_NEXT_ROW, 0x400

.equ P1_DEFAULT_START_POS, 0x08004840
.equ P2_DEFAULT_START_POS, 0x08004A40

.global _start
_start:

INIT:			   		/*EVERYTHING THAT ONLY RUNS ON STARTUP HERE*/
 	movia sp, 0x10000 	/*INIT Stack pointer at reasonable address */
 
				   		/*CLEAR ALL REGISTERS ON A FRESH BOOT/START */
 	mov r2,r0  			#r2 mainly used for Mem Addresses in the VGA space 
 	mov r3,r0  			#r3 mainly used for Mem Addresses in the VGA space
 	mov r4,r0			#will be used to hold pixel color values
 	mov r5,r0			#will always hold address of SWITCH mem region
 	mov r6,r0
 	mov r7,r0
 	mov r8,r0
 	mov r9,r0
 	mov r10,r0
 	mov r11,r0
 	mov r12,r0
 	mov r13,r0
 	mov r14,r0
 	mov r15,r0
 	mov r16,r0
 	mov r17,r0
 	mov r18,r0
 	mov r19,r0
 	mov r20,r0
 	mov r21,r0
 	mov r22,r0
 	mov r23,r0
									
 	movia r2,PIXEL_BUFFER_START		
 	movia r3,PIXEL_BUFFER_END
 	movui r4,0x0000 				/*Black Pixel MOVED HERE FOR TEST*/
 	movia r5,SWITCH_BUFFER 			/*init r5 to start of switch buffer location*/
 
################################################################## 
PAINT_FULL_VGA:
 	beq r2,r3,END_PAINT_FULL_VGA
 	sthio r4,(r2)
 	addi r2,r2,2
 	br PAINT_FULL_VGA
	
END_PAINT_FULL_VGA:
 	movia r2,PIXEL_BUFFER_START
 	mov r4,r0
##################################################################	
 	movia r2,((PIXEL_BUFFER_START+VGA_HALF_ROW_VIS_WIDTH)-0x06) 		/*Move address into r2 where we want to start drawing*/
 	call DRAW_BOUNDARY  												/*Call subroutine DRAW_BOUNDARY*/
	
	movia r2, Player1
	movia r3,P1_DEFAULT_START_POS
	stw r3,(r2) 		/* MAKE CURRENT AND LAST POS SAME ON INIT*/
	stw r3,4(r2)
	movia r2, Player2
	movia r3,P2_DEFAULT_START_POS
	stw r3,(r2)  		/* MAKE CURRENT AND LAST POS SAME ON INIT*/
	stw r3,4(r2)
	
	movia r2,Ball_Cords /*code here to start ball POS*/
	movia r3, (PIXEL_BUFFER_START+0x100+(VGA_SIZE_NEXT_ROW*10))
	stw r3,(r2)  		/* MAKE CURRENT AND LAST POS SAME ON INIT*/
	stw r3,4(r2)
	stw r0,8(r2) /*No velocity yet*/
	stw r0,12(r2)
	
##############################################################################
GAMELOOP: 							/*MAIN GAME LOOP*/

	call GET_INPUT
	call BALL_PHYS
	movia r14,15000
	
WAIT_LOOP:
	nop
	nop
	nop
	nop
	nop
	addi r15,r15,1
	bne r15,r14,WAIT_LOOP
	mov r14,r0
	mov r15,r0
	
 	call DRAW						/*Call the draw subroutine*/
 	jmpi GAMELOOP					/*Jump back to label GAMELOOP infinitly*/
##############################################################################	
DRAW: 											/*Drawing Subroutine to handle all drawing logic*/
 	subi sp,sp,4 								/*Reserve 4 bytes on the stack*/
 	stw ra,(sp) 								/*Store the current return Address on the stack*/

 	mov r10,r0  								/*Ensure some registers are zerod for use in Drawing functions*/
 	mov r11,r0
 	mov r12,r0
 	mov r13,r0
 
	movia r3,Player1
	movui r4,0xff00  /*Move pixel value into r4*/
	ldw r6,(r3)
 	ldw r2,4(r3) 						/*Move address into r2 the chosen test spot to start Player 1*/ 
 	call DRAW_PLAYER
 
 
	movia r3,Player2
	movui r4,0xf0ff
	ldw r6,(r3)
 	ldw r2,4(r3) 						/*Move address into r2 the chosen test spot to start Player 2*/
 	call DRAW_PLAYER
 
 	movia r3,Ball_Cords 
	ldw r6,(r3)
 	ldw r2,4(r3)
	ldw r7,8(r3)
	ldw r8,12(r3)
 	call DRAW_BALL
	
 	#call DRAW_SCORE
 
 	ldw ra,(sp) 		 							/*Restore return address to return to GAMELOOP*/
 	addi sp,sp,4		 							/*Update Stack Pointer*/
 	ret
	
##############################################################################
BALL_PHYS:
 	subi sp,sp,4   /*Set up stack*/
 	stw ra,(sp)
	
	movia r3, Ball_Cords /*Test Give down Y velocity */
	ldw r6, 4(r3) /*Load Current Pos*/
	stw r6, (r3) /*Store Current as Old Pos*/
	ldw r10, 8(r3) /*Load Current X Velo */
	ldw r7, 12(r3) /*Load Current Y velo*/
	
	movia r10, 2 /*Set X Velo to 1*/
	movia r7, 1 /*Set Y Velo to 1*/
	
	movia r8, VGA_SIZE_NEXT_ROW
	mul r9, r8, r7 /*Multiply current y velo by Row size */
	add r6, r6, r9 /*Move down that many rows*/
	sub r6, r6, r10 /*Test left movement*/
	
	stw r7, 12(r3)
	stw r6, 4(r3)
	
	mov r3, r0
	mov r6, r0
	mov r7, r0
	mov r8, r0
	mov r9, r0
	
	ldw ra,(sp) 		 							/*Restore return address to return to GAMELOOP*/
 	addi sp,sp,4		 							/*Update Stack Pointer*/
	ret
	
##############################################################################
DRAW_PLAYER:
 	subi sp,sp,4   /*Set up stack*/
 	stw ra,(sp)
 
 	mov r10,r0  /*Clear r10 and r11 for loop use*/
 	mov r11,r0
 	movia r12,4  /*Player Pixel Draw Width */
 	movia r13,30 /*Player Pixel Draw Height */
 
 D_P_ROW:
 	beq r10,r12, D_P_NEXTROW /*loop control to move to next row*/
 	sthio r4,(r2) /*store pixel color value into pixel memory region */
 	addi r2,r2,2 /*move two bytes over on current memory address*/
 	addi r10,r10,1 
 	br D_P_ROW
	
 D_P_NEXTROW:
 	addi r2,r2, 1016 /*add the offset in memory to start drawing on next row */
	mov r10,r0
	addi r11,r11,1
	bne r11,r13,D_P_ROW
	br DONE_P
	
 DONE_P:
  	mov r10,r0
 	mov r11,r0
 	mov r13,r0
	
	movui r4,0x0000 /*Black pixel value*/
	ldw r2,4(r3)
	
	bgt r2,r6,BLACK_OLD_PXD
	ble r2,r6,BLACK_OLD_PXU

BLACK_OLD_PXU:
	addi r6,r6,(VGA_SIZE_NEXT_ROW * 30)

BLACK_OLD_PXD:
 	beq r10,r12, BLACK_END
 	sthio r4,(r6)
 	addi r6,r6,2
 	addi r10,r10,1
 	br BLACK_OLD_PXD
	
BLACK_END:
 	ldw ra,(sp)
	addi sp,sp,4
 	ret
	
#########################################################################################
DRAW_BALL: 
	subi sp,sp,4 			/*Allocate Space for Stack Pointer*/
 	stw ra,(sp)  			/*Store Return Address on Stack */
	
	mov r10,r0  	/*Clear r10 and r11 for loop use*/
 	mov r11,r0
 	movia r12,6  	/*Ball Pixel Draw Width */
 	movia r13,6 	/*Ball Pixel Draw Height */
	movui r4,0x0000
	
 BLACK_BALL_ROW:
 	beq r10,r12, BLACK_BALL_NEXTROW /*loop control to move to next row*/
 	sthio r4,(r6) /*store pixel color value into pixel memory region */
 	addi r6,r6,2 /*move two bytes over on current memory address*/
 	addi r10,r10,1 
 	br BLACK_BALL_ROW
	
 BLACK_BALL_NEXTROW:
 	addi r6,r6,VGA_SIZE_NEXT_ROW-12  /*add the offset in memory to start drawing on next row */
	mov r10,r0
	addi r11,r11,1
	bne r11,r13,BLACK_BALL_ROW
	
	mov r10,r0  	/*Clear r10 and r11 for loop use*/
 	mov r11,r0
	movui r4,0xffff
	
 BALL_ROW:
 	beq r10,r12, BALL_NEXTROW /*loop control to move to next row*/
 	sthio r4,(r2) /*store pixel color value into pixel memory region */
 	addi r2,r2,2 /*move two bytes over on current memory address*/
 	addi r10,r10,1 
 	br BALL_ROW
	
 BALL_NEXTROW:
 	addi r2,r2,VGA_SIZE_NEXT_ROW-12  /*add the offset in memory to start drawing on next row */
	mov r10,r0
	addi r11,r11,1
	bne r11,r13,BALL_ROW
	br DONE_BALL
	
 DONE_BALL:
 	stw r2,(r3)
  	mov r10,r0
 	mov r11,r0
 	mov r13,r0	
 	ldw ra,(sp) 		/*Restore Return Adress*/
 	addi sp,sp,4	
 	ret
	
#######################################################################################
DRAW_SCORE: /*Not implemented*/
 	movui r4,0xffff 
 	ret
	
#######################################################################################
DRAW_BOUNDARY:
 	movui r4,0xffff 		/*White Pixel*/
 	subi sp,sp,4 			/*Allocate Space for Stack Pointer*/
 	stw ra,(sp)  			/*Store Return Address on Stack */
 
 	movia r3, ((PIXEL_BUFFER_START+VGA_HALF_ROW_VIS_WIDTH)+0x06) /*Choose Right Spot to start Drawing*/
 	mov r10,r0 			/* Clear r10 */
 	mov r13,r0 			/* Clear r13 */
 	movia r11,5 		/*Height of Each Square*/
	movia r12,19 		/*Total Squares in Middle Bound*/
 
 DRAW_SQUARE:
  	beq r2,r3, NEXT_DRAW_ROW 	/*Branch when Current pixel = end mem address of where we want to stop drawing*/
  	sthio r4,(r2)
  	addi r2,r2,2
  	br DRAW_SQUARE
  
 NEXT_DRAW_ROW:
  	addi r2,r2, (VGA_SIZE_NEXT_ROW-0xC)
  	addi r3,r3, VGA_SIZE_NEXT_ROW
  	addi r10,r10,1
  	bne r10,r11,DRAW_SQUARE
  	mov r10,r0 				/* Clear r10 */
  	addi r13,r13,1
  	addi r2,r2,0x2000 		/*Move Pointer for Current Pixel down 10 rows */
  	addi r3,r3,0x2000 		/*Move Mem Address for last Row Pixel down 10 rows */
  	bne r12,r13,DRAW_SQUARE
 	br BOUND_DONE
  
BOUND_DONE: 
 	mov r10,r0 		/*Restore Used Registers*/
 	mov r11,r0
 	mov r12,r0
 	mov r13,r0
 	ldw ra,(sp) 		/*Restore Return Adress*/
 	addi sp,sp,4
 	ret
	
####################################################################################
GET_INPUT:
 	subi sp,sp,4 			/*Allocate Space for Stack Pointer*/
 	stw ra,(sp)
	ldhio r17,(r5)
	#break/*check is button is pressed by value loaded into r19*/
	
CHECK_P1_UP:	
	movia r18, 0x0001 		/*move hex value to r18 to check against switch press */
	and r19,r18,r17 		/* AND r17 and r18, r17 holds the values of the switches*/
	beq r18,r19,MOVE_P1_UP /*branch if the result from AND matches out test hex value */
	
CHECK_P1_DOWN:	
	movia r18, 0x0002
	and r20,r18,r17
	beq r18,r20,MOVE_P1_DOWN
	
CHECK_P2_UP:	
	movia r18, 0x0004
	and r21,r18,r17
	beq r18,r21,MOVE_P2_UP
	
CHECK_P2_DOWN:		
	movia r18, 0x0008
	and r22,r18,r17
	beq r18,r22,MOVE_P2_DOWN
	br END_INPUT
	
MOVE_P1_UP:
	movia r3,Player1	 /*load memory address where player values are stored*/
	ldw r2,4(r3) 		/* load current px position into r2 */
	stw r2,(r3) 		/* store current px position as last px position in memory*/
	subi r2,r2,(VGA_SIZE_NEXT_ROW * 1) /*Set player position px to 1 pixel (row) above it current pos*/
	movia r7,PIXEL_BUFFER_START  /*check if top of the screen has been reached*/
	blt r2,r7,MOVE_P1_DOWN   /*If top of the screen move player back down 1 pixel*/
	stw r2,4(r3)  /*If position is valid store in Player 1 last pos memory locaiton */
	br CHECK_P1_DOWN
	
MOVE_P1_DOWN:
	movia r3,Player1
	ldw r2,4(r3)
	stw r2,(r3)
	addi r2,r2,(VGA_SIZE_NEXT_ROW * 1)
	movia r7,(PIXEL_BUFFER_END-(VGA_SIZE_NEXT_ROW * 30))
	bgt r2,r7,MOVE_P1_UP	
	stw r2,4(r3)
	br CHECK_P2_UP
	
MOVE_P2_UP:
	movia r3,Player2
	ldw r2,4(r3)
	stw r2,(r3)
	subi r2,r2,(VGA_SIZE_NEXT_ROW * 1)
	movia r7,PIXEL_BUFFER_START
	blt r2,r7,MOVE_P2_DOWN
	stw r2,4(r3)	
	br CHECK_P2_DOWN
	
MOVE_P2_DOWN:
	movia r3,Player2
	ldw r2,4(r3)
	stw r2,(r3)
	addi r2,r2,(VGA_SIZE_NEXT_ROW * 1)
	movia r7, (PIXEL_BUFFER_END-(VGA_SIZE_NEXT_ROW * 30))
	bgt r2,r7,MOVE_P2_UP
	stw r2,4(r3)
	
END_INPUT:
	mov r7,r0
	mov r17,r0
	mov r18,r0
	mov r19,r0
	mov r20,r0
	mov r21,r0
	mov r22,r0
 	ldw ra,(sp) 		/*Restore Return Adress*/
 	addi sp,sp,4
 	ret
#########################################################################	
 .data 
	Player1:
		.skip 4 /* P1 LAST X POS */
		.skip 4 /* P1 CURRENT X POS */
	Player2:
		.skip 4 /* P2 LAST X POS */
		.skip 4 /* P2 Current X POS */
	Ball_Cords:
		.skip 4 /* Ball LAST X POS */
		.skip 4 /* Ball Current X POS */
		.skip 4 /* Ball X velocity*/
		.skip 4 /* Ball Y velocity*/
	Score:
		.skip 4 /* P1 Score */
		.skip 4 /* P2 Score */