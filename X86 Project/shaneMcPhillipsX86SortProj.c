/************************************************************************
 *
 *       x86 sort project : 
 *
 *		implement sort (either insertion sort)
 *		translated from the Mips sort project
 *
 *
 *************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cse222macV4.h"
#define HALFPOINT 1
#define NO_HALFPOINT 0
/*
 * declare the prototype of your assembler program or procedures
 */
// example: short asmreturn();  

void asmSort(int *list, int arrayLen, int halfpoint);
void processConfigs(int argc,char *argv[] );
void asm_insertion_sort (int *a, int n, int hpts);
void selection_sort (int *a, int n, int hpts);
void restoreOrigArray(int *origAry,int *wrkAry, int n);
void printList(int *list, int arrayLen);
int letsCheckTheSort();
int compareCheck(int *myLst,int *stuLst, int cntN);
int letsTimeTheSort();


int  numCount = 20;
int  originalNumber[100] = {5, 8, 12, 10, 56, 22, 98, 120, 90, 4, 349, 8, 45, 37, 43, 67, 3, 18, 97, 71};
int  listOfNumber[100]   = {5, 8, 12, 10, 56, 22, 98, 120, 90, 4, 349, 8, 45, 37, 43, 67, 3, 18, 97, 71};
char sortType = 'I';   // 'I' for insert sort otherwise it is selection sort

main(int argc, char *argv[] )
{
	/* 
	 * variable declaration here
	 */

	int tmp1 = 0;
	processConfigs(argc,argv);
    

   /*
	* First call INITCST
	* replace Your Name Here with your name
	*/

	INITCST("Fall 2018 Sort routine using x86: ","Shane McPhillips");
	sortType = 'I';   // 'I' capital I for insert sort otherwise it is selection sort


	/*
	 * call your asm procedure here
	 * you can use any variable name you want and make sure the return type
	 * is correct.
	 */


	asmSort(listOfNumber, numCount, HALFPOINT);
	printList(listOfNumber, numCount);

	if (letsCheckTheSort() == 0) {
		printf("\n You have pass the sort check.....  now let's time it ......\n\n");
		letsTimeTheSort();
	}
	else printf("\n********* sort fail on the check sort\ncan not continue for timing \n");
	
	printf("\n\n\nhit any key to continue or quit");
	getchar();
}



void restoreOrigArray(int *origAry,int *wrkAry, int n) {
	int i;
	for (i=0; i<n; i++) {
		wrkAry[i] = origAry[i];
	}
}


void printList(int *list, int arrayLen) {
	int i;
	for ( i = 0; i<arrayLen; i++) {
		printf("%5d",*list);
		if ((i+1) % 10 == 0) printf("\n");
		list++;
	}
	printf("\n");
}



void asmSort(int *list, int arrayLen, int halfpoint) {
	/*if (halfpoint)
		arrayLen = arrayLen / 2;

	//Loop through elements
	for (int i = 1; i < arrayLen; i++)
	{

		int key = list[i];
		int previous = i - 1;

		while (previous >= 0 && list[previous] > key)
		{
			list[previous + 1] = list[previous];
			previous -= 1;
		}

		list[previous + 1] = key;

	} return;*/

	_asm 
	{

		mov ecx, arrayLen
		mov esi, DWORD PTR [list]
		mov eax, 1 //i = 1
		mov ebx, halfpoint

		cmp ebx, 0
		je loop_start
		shr ecx, 1 // arrayLen = arrayLen/2

		loop_start:
			mov edx, DWORD PTR[esi][eax*4] //key = list[i]
			mov ebx, eax //j = i
			sub ebx, 1 //j = i-1
		
			
		while_loop:
			//while loop conditions
			cmp [esi + ebx*4], edx //list[previous] <= key? exit loop
			jle loop_end

			//Inside while loop
			mov edi, [esi][ebx*4] //edi = list[previous]
			mov [esi + ebx*4 + 4], edi //list[previous + 1] = list[previous]

			sub ebx, 1 //previous = previous - 1
			jge while_loop

		//where the loop ends
		loop_end:
			mov[esi + ebx*4 + 4], edx //list[previous + 1] = key
			add eax, 1 //i++
			cmp eax, ecx //i >= arrayLen, exit
			jge finished
			jmp loop_start

		finished:
			//done.
	}
	return;

}
