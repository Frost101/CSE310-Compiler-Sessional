%{
#include<bits/stdc++.h>
#include "1905101.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

int line_count = 1;
int errorCount = 0;
bool errorFlag = false;
int errorLine = 1;			//For expression statement

ofstream logout("log.txt");
ofstream errorout("error.txt");
ofstream treeout("parseTree.txt");
ofstream asm2out("asm.asm");
ofstream optout("optcode.asm");

/*		For ICG parstree traversing		*/
void start(SymbolInfo* node);
void program(SymbolInfo* node);
void unit(SymbolInfo* node);
void func_declaration(SymbolInfo* node);
void func_definition(SymbolInfo* node);
void parameter_list(SymbolInfo* node);
void compound_statement(SymbolInfo* node);
void var_declaration(SymbolInfo* node);
void type_specifier(SymbolInfo* node);
void declaration_list(SymbolInfo* node);
void statements(SymbolInfo* node);
void statement(SymbolInfo* node);
void expression_statement(SymbolInfo* node);
void variable(SymbolInfo* node);
void expression(SymbolInfo* node);
void logic_expression(SymbolInfo* node);
void rel_expression(SymbolInfo* node);
void simple_expression(SymbolInfo* node);
void term(SymbolInfo* node);
void unary_expression(SymbolInfo* node);
void factor(SymbolInfo* node);
void argument_list(SymbolInfo* node);
void arguments(SymbolInfo* node);
void enter_new_scope(SymbolInfo* node);


/*		Helper Function		*/
void forPrintln();
void printParseTree(SymbolInfo* si,int depth);


int bucketSize = 11;
SymbolTable *table = new SymbolTable(bucketSize);
SymbolTable *table2 = new SymbolTable(bucketSize);


/*		To detect Functions 	*/
vector<SymbolInfo*> params;
vector<SymbolInfo*>params2;
bool isFunction = false;
string retLabel = "";


/*		To insert global variable into asm file		*/
vector<SymbolInfo*> globalVar;
int offset = 0;				//For local variables
int labelCount = 0;			//For generating unique label
string currentLabel = "";	//Current Unique label
SymbolInfo* startNode;


/*		To Generate Unique Label		*/
string newLabel(){
	labelCount++;
	string tmp = "L"+ to_string(labelCount);
	return tmp ;
}


/*		For println to work		*/
void forPrintln(){

	ofstream out;
	asm2out.close();

	out.open("asm.asm",ios::app);


	out << "new_line proc" << endl;
    out << "\t" << "push ax" << endl;
    out << "\t" << "push dx" << endl;
    out << "\t" << "mov ah,2" << endl;
   	out << "\t" << "mov dl,cr" << endl;
    out << "\t" << "int 21h" << endl;
    out << "\t" << "mov ah,2" << endl;
    out << "\t" << "mov dl,lf" << endl;
    out << "\t" << "int 21h" << endl;
    out << "\t" << "pop dx" << endl;
    out << "\t" << "pop ax" << endl;
    out << "\t" << "ret" << endl;
	out << "new_line endp" << endl;
	out << "print_output proc  ;print what is in ax " << endl;
    out << "\t" << "push ax"  << endl;
    out << "\t" << "push bx" << endl;
    out << "\t" << "push cx" << endl;
    out << "\t" << "push dx" << endl;
    out << "\t" << "push si" << endl;
    out << "\t" << "lea si,number" << endl;
    out << "\t" << "mov bx,10" << endl;
    out << "\t" << "add si,4" << endl;
    out << "\t" << "cmp ax,0" << endl;
    out << "\t" << "jnge negate" << endl;
    out << "\t" << "print:" << endl;
    out << "\t" << "xor dx,dx" << endl;
    out << "\t" << "div bx" << endl;
    out << "\t" << "mov [si],dl" << endl;
    out << "\t" << "add [si],\'0\' " << endl; 
    out << "\t" << "dec si" << endl;
    out << "\t" << "cmp ax,0" << endl;
    out << "\t" << "jne print" << endl;
    out << "\t" << "inc si" << endl;
    out << "\t" << "lea dx,si" << endl;
    out << "\t" << "mov ah,9" << endl;
    out << "\t" << "int 21h" << endl;
    out << "\t" << "pop si" << endl;
    out << "\t" << "pop dx" << endl;
    out << "\t" << "pop cx" << endl;
    out << "\t" << "pop bx" << endl;
    out << "\t" << "pop ax" << endl;
    out << "\t" << "ret" << endl;
    out << "\t" << "negate:" << endl;
    out << "\t" << "push ax" << endl;
    out << "\t" << "mov ah,2" << endl;
    out << "\t" << "mov dl,\'-\' " << endl;
    out << "\t" << "int 21h" << endl;
    out << "\t" << "pop ax" << endl;
    out << "\t" << "neg ax" << endl;
    out << "\t" << "jmp print" << endl;
	out << "print_output endp" << endl;
	out << "END main" << endl;

	out.close();
}



void optimize(){
	ifstream inFile;
	inFile.open("asm.asm");
	string inLine = "";
	vector<string> unoptCode;

	/*		take input		*/
	while(getline(inFile, inLine))unoptCode.push_back(inLine);


	/*		iterate and optimize		*/
	for(int i=0; i < unoptCode.size(); i++){
		if(i+1 >= unoptCode.size()){
			/*		Do Nothing		*/
			optout << unoptCode[i] << endl;
			continue;
			
		}
		else if(unoptCode[i].substr(1,3) == "ADD"){
			string tmp = unoptCode[i];
			int idx = tmp.find(",");
			if(tmp.substr(idx+2) == "0"){
				optout << "\t\t" << ";Unnecessary ADD has been removed" << endl;
				continue;
			}
		}
		else if(unoptCode[i].substr(1,3) == "SUB"){
			string tmp = unoptCode[i];
			int idx = tmp.find(",");
			if(tmp.substr(idx+2) == "0"){
				optout << "\t\t" << ";Unnecessary SUB has been removed" << endl;
				continue;
			}
		}
		else if(unoptCode[i].substr(1,3) == "MOV" && unoptCode[i+1].substr(1,3) == "MOV"){
			/*		MOV AX, BX
					MOV BX, AX			*/

			string tmp1 = unoptCode[i].substr(4);
			string tmp2 = unoptCode[i+1].substr(4);
			int idx1 = tmp1.find(",");
			int idx2 = tmp2.find(",");

			if((tmp1.substr(1,idx1 - 1) == (tmp2.substr(idx2 + 2))) && (tmp1.substr(idx1 + 2) == (tmp2.substr(1,idx2 - 1)))){
				optout << "\t\t" << ";Redundant MOV instruction has been removed " << endl;
				optout << unoptCode[i] << endl;
				i++;
				continue;
			}

		}
		else if(unoptCode[i].substr(1,4) == "PUSH" && unoptCode[i+1].substr(1,3) == "POP"){
			/*		PUSH AX
					POP AX		*/
			string tmp1 = unoptCode[i];
			string tmp2 = unoptCode[i+1];

			if(tmp1.substr(6) == tmp2.substr(5)){
				optout << "\t\t" << ";Unnecessary PUSH POP instructions have been removed " << endl;
				i++;
				continue;
			}
		}

		optout << unoptCode[i] << endl;
	}
}



/*		ICG non-terminal function portion starts		*/


void start(SymbolInfo* node){
    asm2out << ".MODEL SMALL" << endl;
	asm2out << ".STACK 1000H" << endl;
	asm2out << ".Data" << endl;
	asm2out << "\t" << "CR EQU 0DH" << endl;
	asm2out << "\t" << "LF EQU 0AH" << endl;
	asm2out << "\t" << "number DB \"00000$\"" << endl;

	for(int i=0; i<globalVar.size(); i++){
			table2->insert(*(globalVar[i]));
			if(globalVar[i]->isArray){
				//My_Array DB 100 DUP(?)
				asm2out << "\t" << globalVar[i]->name << " DW "<< globalVar[i]->arraySize <<" DUP (0000H)" <<endl;
			}
			else{
				asm2out << "\t" << globalVar[i]->name << " DW 1 DUP (0000H)" <<endl;
			}
		}

		asm2out << ".CODE" << endl;
    program(node->childList[0]);
	forPrintln();
	asm2out.close();
	optimize();
}



void program(SymbolInfo* node){
	if(node->childList[0]->type == "program"){
		program(node->childList[0]);
		unit(node->childList[1]);
	}
	else if(node->childList[0]->type == "unit"){
		unit(node->childList[0]);
	}
}


void unit(SymbolInfo* node){
	if(node->childList[0]->type == "var_declaration"){
		
	}
	else if(node->childList[0]->type == "func_declaration"){

	}
	else if(node->childList[0]->type == "func_definition"){
		func_definition(node->childList[0]);
	}
}


void func_declaration(SymbolInfo* node){

}


void func_definition(SymbolInfo* node){
	params2.clear();								//Reset parameter_list
	offset = 0;										//Reset offset count		
	asm2out << "\t\t;Line no# " << node->startLine <<": " << node->childList[1]->name << " starts" << endl;							
	asm2out << node->childList[1]->name << " PROC" << endl;
	if(node->childList[1]->name == "main"){
		asm2out << "\tMOV AX, @DATA" << endl;
		asm2out << "\tMOV DS, AX"  << endl;
	}
	asm2out << "\t" << "PUSH BP" << endl;
	asm2out << "\t" << "MOV BP, SP" << endl;
	retLabel = newLabel();					//Generate new label
	

	if(node->childList[3]->type == "parameter_list"){
		parameter_list(node->childList[3]);
		offset -= 2;
		
		for(int i=0; i<(node->childList[1]->paramList.size()); i++){
			params2.push_back(node->childList[1]->paramList[i]);
			offset -= 2;
			params2[i]->offset = offset;
		}
		

		offset = 0;			//Reset Offset again
		compound_statement(node->childList[5]);

	}
	else{
		compound_statement(node->childList[4]);
	}


	asm2out << retLabel << ":" << endl;
	asm2out << "\tADD SP, " << offset << endl;
	asm2out << "\tMOV SP, BP" << endl;			//newly added line
	asm2out << "\t" << "POP BP" << endl;
	
	if(node->childList[1]->name != "main"){
		asm2out << "\t" << "RET " << (params2.size() * 2) << endl;

	}
	else{
		asm2out << "\tMOV AX,4CH" << endl;
		asm2out << "\tINT 21H" << endl;
	}
	asm2out << node->childList[1]->name << " ENDP" <<endl;
	asm2out << "\t\t;Line no# " << node->endLine <<": " << node->childList[1]->name << " ends" << endl;

	offset = 0;										//reset offset
}


void parameter_list(SymbolInfo* node){
	return;
}


void compound_statement(SymbolInfo* node){
	if(node->childList[1]->type == "statements"){
		enter_new_scope(node->childList[1]);		//dummy child
		for(int i=0;i<params2.size();i++){
			table2->insert(*(params2[i]));
		}

		statements(node->childList[1]);
		
	}
	else{
		enter_new_scope(node->childList[1]);		//dummy child
		for(int i=0;i<params2.size();i++){
			table2->insert(*(params2[i]));
		}
	}
	table2->exitScope();
}


void var_declaration(SymbolInfo* node){
	
	declaration_list(node->childList[1]);
}


void type_specifier(SymbolInfo* node){

}


void declaration_list(SymbolInfo* node){
	node->childList[0]->isArray = false;
	if(node->childList.size()==1){
		/*		declaration_list : ID		*/
		if(table2->currentScopeNo() == 1){
			//Global declaration....
			node->childList[0]->isGlobal = true;
			table2->insert(*(node->childList[0]));
		}
		else{
			offset += 2;
			node->childList[0]->offset = offset;
			asm2out << "\t" << "SUB SP, 2" << endl;
			table2->insert(*(node->childList[0]));
		}
	}
	else if(node->childList.size()==3){
		/*		declaration_list : declaration_list COMMA ID		*/
		declaration_list(node->childList[0]);
		node->childList[2]->isArray = false;
		if(table2->currentScopeNo() == 1){
			/*		Global....		*/
			node->childList[2]->isGlobal = true;
			table2->insert(*(node->childList[2]));
		}
		else{
			offset += 2;
			node->childList[2]->offset = offset;	
			asm2out << "\t" << "SUB SP, 2" << endl;
			table2->insert(*(node->childList[2]));
		}
	}
	else if(node->childList.size()==4){
		/*		declaration_list : ID LTHIRD CONST_INT RTHIRD		*/
		node->childList[0]->isArray = true;
		node->childList[0]->arraySize = stoi(node->childList[2]->name);
		if(table2->currentScopeNo() == 1){
			/*		Global...	*/
			node->childList[0]->isGlobal = true;
			table2->insert(*(node->childList[0]));
		}
		else{
			offset += 2;
			node->childList[0]->offset = offset;
			offset -= 2;
			offset += (2 * (node->childList[0]->arraySize));
			asm2out << "\t" << "SUB SP, " << (2 * (node->childList[0]->arraySize)) << endl;
			table2->insert(*(node->childList[0]));
		}

	}
	else if(node->childList.size()==6){
		/*		declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD		*/
		declaration_list(node->childList[0]);
		node->childList[2]->isArray = true;
		node->childList[2]->arraySize = stoi(node->childList[4]->name);

		if(table2->currentScopeNo() == 1){
			/*		Global...	*/
			node->childList[2]->isGlobal = true;
			table2->insert(*(node->childList[2]));
		}
		else{
			offset += 2;
			node->childList[2]->offset = offset;
			offset -= 2;
			offset += (2 * (node->childList[2]->arraySize));
			asm2out << "\t" << "SUB SP, " << (2 * (node->childList[2]->arraySize)) << endl;
			table2->insert(*(node->childList[2]));
		}
	}
}


void statements(SymbolInfo* node){
	if(node->childList[0]->type == "statements"){
		statements(node->childList[0]);
		statement(node->childList[1]);
	}
	else{
		statement(node->childList[0]);
	}
}


void statement(SymbolInfo* node){
	if(node->childList[0]->type == "var_declaration"){
		/*		statement : var_declaration		*/
		var_declaration(node->childList[0]);
	}
	else if(node->childList[0]->type == "expression_statement"){
		/*		statement : expression_statement		*/
		
		expression_statement(node->childList[0]);
	}
	else if(node->childList[0]->type == "PRINTLN"){
		/*		statement : PRINTLN LPAREN ID RPAREN SEMICOLON		*/
		SymbolInfo* symbol = table2->lookUp(node->childList[2]->name);
		if(symbol->isGlobal){
			asm2out << "\tMOV AX, " << symbol->name << endl;
		}
		else{
			asm2out << "\tMOV AX, [BP- " << symbol->offset << "]" << endl;
		}
				
		asm2out << "\tCALL print_output" << endl;
		asm2out << "\tCALL new_line" << endl;
	}
	else if(node->childList[0]->type == "WHILE"){
		/*		statement : WHILE LPAREN expression RPAREN statement		*/

		string endLabel = newLabel();
		string loopLabel = newLabel();

		asm2out << loopLabel << ":" << endl;
		expression(node->childList[2]);
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "CMP AX,0" << endl;
		asm2out << "\t" << "JE " << endLabel << endl;

		statement(node->childList[4]);
		asm2out << "\t" << "JMP " << loopLabel << endl;

		asm2out << endLabel << ":" << endl;
	}
	else if(node->childList[0]->type == "compound_statement"){
		/*		statement : compound_statement		*/

		compound_statement(node->childList[0]);
	}
	else if(node->childList[0]->type == "FOR"){
		/*		statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement		*/
		string loopLabel = newLabel();
		string skipLabel = newLabel();
		string endLabel = newLabel();

		asm2out << "\t\t" << ";Line no# " << node->startLine << ": FOR loop starts " << endl;

		expression_statement(node->childList[2]);

		asm2out << loopLabel << ":" << endl;
		expression_statement(node->childList[3]);
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "CMP AX, 0" << endl;
		asm2out << "\t" << "JE " << endLabel << endl;

		statement(node->childList[6]);

		expression(node->childList[4]);
		asm2out << "\t" << "JMP " << loopLabel << endl;

		asm2out << endLabel << ":" << endl;

		asm2out << "\t\t" << ";Line no# " << node->endLine << ": FOR loop ends " << endl;
	}
	else if(node->childList[0]->type == "IF"){
		if(node->childList.size()==5){
			/*		statement : IF LPAREN expression RPAREN statement		*/

			string endLabel = newLabel();

			asm2out << "\t\t" << ";Line no# " << node->startLine << ": Only if block starts " << endl;

			expression(node->childList[2]);
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t" << "CMP AX,0" << endl;
			asm2out << "\t" << "JE " << endLabel << endl;

			statement(node->childList[4]);

			asm2out << endLabel << ":" << endl;

			asm2out << "\t\t" << ";Line no# " << node->endLine << ": Only if block ends " << endl;
		}
		else{
			/*		statement : IF LPAREN expression RPAREN statement ELSE statement		*/

			string elseLabel = newLabel();
			string skipLabel = newLabel();

			asm2out << "\t\t" << ";Line no# " << node->startLine << ": if-else block starts " << endl;
			
			expression(node->childList[2]);
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t" << "CMP AX,0" << endl;
			asm2out << "\t" << "JE " << elseLabel << endl;

			statement(node->childList[4]);
			asm2out << "\t" << "JMP " << skipLabel << endl;

			asm2out << elseLabel << ":" << endl;
			statement(node->childList[6]);

			asm2out << skipLabel << ":" << endl;

			asm2out << "\t\t" << ";Line no# " << node->endLine << ": if-else block ends " << endl;
		}
	}
	else if(node->childList[0]->type == "RETURN"){
			/*		statement : RETURN expression SEMICOLON		*/
			expression(node->childList[1]);
			asm2out << "\t" << "POP CX" << endl;
			asm2out << "\t" << "JMP " << retLabel << endl;
	}
}


void expression_statement(SymbolInfo* node){
	if(node->childList[0]->type == "expression"){
		expression(node->childList[0]);
	}
}


void variable(SymbolInfo* node){
	if(node->childList.size()==1){
		/*		variable : ID		*/
		SymbolInfo* symbol = table2->lookUp(node->childList[0]->name);
		if(symbol->isGlobal){
			asm2out << "\t\t" << ";Line no# " << node->startLine << ": global var " << endl;
			asm2out << "\t" << "MOV AX, " << symbol->name << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
		else{
			asm2out << "\t\t" << ";Line no# " << node->startLine << ": local var " << endl;
			asm2out << "\t" << "MOV AX, [BP- " << symbol->offset << "]" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
	}
	else if(node->childList.size()==4){
		/*		variable : ID LTHIRD expression RTHIRD		*/
		SymbolInfo* symbol = table2->lookUp(node->childList[0]->name);
		if(symbol->isGlobal){
			expression(node->childList[2]);
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t\t" << ";Line no# " << node->startLine << ": global array " << endl;
			asm2out << "\t" << "LEA SI," << symbol->name << endl;
			asm2out << "\t" << "ADD SI, AX" << endl;
			asm2out << "\t" << "ADD SI, AX" << endl;
			asm2out << "\t" << "MOV AX, [SI]" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
		else{
			expression(node->childList[2]);
			asm2out << "\tPOP BX" << endl;
			asm2out << "\t\t" << ";Line no# " << node->startLine << ": local array " << endl;

			/*		Now Multiply	*/
			asm2out << "\tMOV AX, 2" << endl;
			asm2out << "\t" << "CWD" << endl;
			asm2out << "\t" << "IMUL BX" << endl;
			asm2out << "\tMOV BX, AX" << endl;
			asm2out << "\tADD BX, " << symbol->offset << endl;
			

			/*		Multiplication ends		*/
			//asm2out << "\t\t" << ";Line no# " << node->startLine << ": ***		pushing local variable to stack		*** " << endl;
			
			asm2out << "\t" << "PUSH DI" << endl;
			asm2out << "\t" << "MOV DI, BX" << endl;	
			asm2out << "\t" << "NEG DI" << endl;		
			asm2out << "\t" << "MOV AX, [BP+DI]" << endl;
			asm2out << "\t" << "POP DI" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
	}
}


void expression(SymbolInfo* node){
	if(node->childList[0]->type == "logic_expression"){
		/*		expression : logic_expression		*/
		logic_expression(node->childList[0]);
	}
	else if(node->childList[0]->type == "variable"){
		/*		expression : variable ASSIGNOP logic_expression		*/
		
		variable(node->childList[0]);
		logic_expression(node->childList[2]);
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "POP BX" << endl;
		asm2out << "\tMOV CX, AX" << endl;
		
		SymbolInfo* si =  table2->lookUp(node->childList[0]->childList[0]->name);
		if(si->isGlobal){
			SymbolInfo* symbol = table2->lookUp(node->childList[0]->childList[0]->name);
			if(symbol->isArray){
				asm2out << "\t" << "PUSH AX" << endl;
				expression(node->childList[0]->childList[2]);
				asm2out << "\t" << "POP DX" << endl;
				asm2out << "\t" << "POP AX" << endl;
				asm2out << "\t" << "LEA SI," << symbol->name << endl;
				asm2out << "\t" << "ADD SI, DX" << endl;
				asm2out << "\t" << "ADD SI, DX" << endl;
				asm2out << "\t" << "MOV [SI], AX" << endl;
			}
			else{
				asm2out << "\t" << "MOV " << node->childList[0]->childList[0]->name << ", AX" << endl;
			}
		}
		else{
			SymbolInfo* symbol = table2->lookUp(node->childList[0]->childList[0]->name);
			if(symbol->isArray){
				expression(node->childList[0]->childList[2]);
				asm2out << "\tPOP BX" << endl;
				

				/*		Now Multiply	*/
				asm2out << "\tMOV AX, 2" << endl;
				asm2out << "\t" << "CWD" << endl;
				asm2out << "\t" << "IMUL BX" << endl;
				asm2out << "\tMOV BX, AX" << endl;
				asm2out << "\tADD BX," << symbol->offset << endl;
				/*		Multiplication ends		*/

				asm2out << "\t" << "PUSH DI" << endl;
				asm2out << "\t" << "MOV DI, BX" << endl;
				asm2out << "\t" << "NEG DI" << endl;
				asm2out << "\t" << "MOV [BP+DI], CX" << endl;
				asm2out << "\t" << "POP DI" << endl;
			}
			else{
				asm2out << "\t" << "MOV [BP- " << symbol->offset << "], AX" << endl;
			}			
		}
	}
}


void logic_expression(SymbolInfo* node){
	if(node->childList.size()==1){
		/*		logic_expression : rel_expression		*/
		rel_expression(node->childList[0]);
	}
	else if(node->childList.size()==3){
		/*		logic_expression : rel_expression LOGICOP rel_expression		*/
		rel_expression(node->childList[0]);
		rel_expression(node->childList[2]);

		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "POP BX" << endl;

		string trueLabel = newLabel();
		string falseLabel = newLabel();
		string skipLabel = newLabel();

		if(node->childList[1]->name == "&&"){
			string nextLabel = newLabel();
			asm2out << "\t" << "CMP BX,0" << endl;
			asm2out << "\t" << "JNE " << nextLabel << endl;
			asm2out << "\t" << "JMP " << falseLabel << endl;

			asm2out << nextLabel << ":" << endl;
			asm2out << "\t" << "CMP AX,0" << endl;
			asm2out << "\t" << "JNE " << trueLabel << endl;
			asm2out << "\t" << "JMP " << falseLabel << endl;
		}
		else if(node->childList[1]->name == "||"){
			asm2out << "\t" << "CMP BX,0" << endl;
			asm2out << "\t" << "JNE " << trueLabel << endl;

			asm2out << "\t" << "CMP AX,0" << endl;
			asm2out << "\t" << "JNE " << trueLabel << endl;
			asm2out << "\t" << "JMP " << falseLabel << endl;
		}

		asm2out << trueLabel << ":" << endl;
		asm2out << "\t" << "MOV AX, 1" << endl;
		asm2out << "\t" << "JMP " << skipLabel << endl;

		asm2out << falseLabel << ":" << endl;
		asm2out << "\t" << "MOV AX, 0" << endl;
		
		asm2out << skipLabel << ":" << endl;
		asm2out << "\t" << "PUSH AX" << endl;

	}
}


void rel_expression(SymbolInfo* node){
	if(node->childList.size()==1){
		/*		rel_expression : simple_expression		*/
		simple_expression(node->childList[0]);
	}
	else if(node->childList.size()==3){
		/*		rel_expression : simple_expression RELOP simple_expression		*/
		simple_expression(node->childList[0]);
		simple_expression(node->childList[2]);

		/*		POP those results who were pushed in simple expression 		*/
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "POP BX" << endl;
		asm2out << "\t\t" << ";Line no# " << node->startLine << endl;

		/*		Create a label for true		*/
		string trueLabel = newLabel();

		/*		Create a label for false/skip		*/
		string skipLabel = newLabel();	

		/*		Check RELOP		*/
		if(node->childList[1]->name == "<"){
			asm2out << "\t" << "CMP BX,AX" << endl;
			asm2out << "\t" << "JL " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl; 
		}
		else if(node->childList[1]->name == "<="){
			asm2out << "\t" << "CMP BX,AX" << endl;
			asm2out << "\t" << "JLE " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl; 
		}
		else if(node->childList[1]->name == ">"){
			asm2out << "\t" << "CMP BX,AX" << endl;
			asm2out << "\t" << "JG " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl;
		}
		else if(node->childList[1]->name == ">="){
			asm2out << "\t" << "CMP BX,AX" << endl;
			asm2out << "\t" << "JGE " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl;
		}
		else if(node->childList[1]->name == "=="){
			asm2out << "\t" << "CMP BX,AX" << endl;
			asm2out << "\t" << "JE " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl; 
		}
		else if(node->childList[1]->name == "!="){
			asm2out << "\t" << "CMP BX, AX" << endl;
			asm2out << "\t" << "JNE " << trueLabel << endl;
			asm2out << "\t" << "MOV AX, 0" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
			asm2out << "\t" << "JMP " << skipLabel << endl; 
		}

		/*		Print True Label		*/
		asm2out << trueLabel << ":" << endl;
		asm2out << "\t" << "MOV AX, 1" << endl;
		asm2out << "\t" << "PUSH AX" << endl;


		/*		Print False/skip Label		*/
		asm2out << skipLabel << ":" << endl;
	}
}


void simple_expression(SymbolInfo* node){
	if(node->childList.size()==1){
		/*		simple_expression : term		*/
		term(node->childList[0]);
	}
	else if(node->childList.size()==3){
		/*		simple_expression : simple_expression ADDOP term		*/
		simple_expression(node->childList[0]);
		term(node->childList[2]);
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t" << "POP BX" << endl;
		asm2out << "\t\t" << ";Line no# " << node->startLine << ": ADDOP found" << endl;

		if(node->childList[1]->name == "+"){
			asm2out << "\t" << "ADD AX, BX" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
		else if(node->childList[1]->name == "-"){
			asm2out << "\t" << "SUB BX, AX" << endl;
			asm2out << "\t" << "PUSH BX" << endl;
		}
	}
}


void term(SymbolInfo* node){
	
	if(node->childList[0]->type == "unary_expression"){
		/*		term : unary_expression		*/
		unary_expression(node->childList[0]);
	}
	else if(node->childList[0]->type == "term"){
		/*		term : term MULOP unary_expression		*/
		term(node->childList[0]);
		unary_expression(node->childList[2]);
		if(node->childList[1]->name == "*"){
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t" << "POP CX" << endl;
			asm2out << "\t" << "CWD" << endl;
			asm2out << "\t" << "IMUL CX" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
		else if(node->childList[1]->name == "/"){
			asm2out << "\t" << "POP BX" << endl;
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t" << "CWD" << endl;
			asm2out << "\t" << "IDIV BX" << endl;
			asm2out << "\t" << "PUSH AX" << endl;
		}
		else if(node->childList[1]->name == "%"){
			asm2out << "\t" << "POP BX" << endl;
			asm2out << "\t" << "POP AX" << endl;
			asm2out << "\t" << "CWD" << endl;
			asm2out << "\t" << "IDIV BX" << endl;
			asm2out << "\t" << "PUSH DX" << endl;
		}
	}
}


void unary_expression(SymbolInfo* node){
	if(node->childList[0]->type == "ADDOP"){
		/*		unary_expression : ADDOP unary_expression		*/
		unary_expression(node->childList[1]);

		
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t\t" << ";Line no# " << node->startLine << ": ADDOP unary_exp " << endl;

		if(node->childList[0]->name == "-"){
			asm2out << "\t" << "NEG AX" << endl;
		}
		asm2out << "\t" << "PUSH AX" << endl;
		
	}
	else if(node->childList[0]->type == "NOT"){
		/*		unary_expression : NOT unary_expression		*/
		unary_expression(node->childList[1]);

		string oneLabel = newLabel();
		string skipLabel = newLabel();

		
		asm2out << "\t" << "POP AX" << endl;
		asm2out << "\t\t" << ";Line no# " << node->startLine << ": NOT unary_expression " << endl;
		//asm2out << "\t" << "CWD" << endl;
		asm2out << "\tCMP AX,0" << endl;
		asm2out << "\tJE " << oneLabel << endl;
		asm2out << "\tMOV AX, 0" << endl;
		asm2out << "\tJMP " << skipLabel << endl;

		asm2out << oneLabel << ":" << endl;
		asm2out << "\t" << "MOV AX, 1" << endl;

		asm2out << skipLabel << ":" << endl;
		asm2out << "\t" << "PUSH AX" << endl;


	}
	else if(node->childList[0]->type == "factor"){
		/*		unary_expression : factor		*/
		factor(node->childList[0]);
	}
}


void factor(SymbolInfo* node){
	
	if(node->childList[0]->type == "variable"){
		if(node->childList.size()==1){
			/*		factor : variable		*/
			variable(node->childList[0]);
		}
		else if(node->childList[1]->type == "INCOP"){
			/*		factor : variable INCOP		*/
			SymbolInfo* symbol = table2->lookUp(node->childList[0]->childList[0]->name);
			//table->print(asm2out);
			if(symbol->isGlobal){
				if(symbol->isArray){
					expression(node->childList[0]->childList[2]);
					asm2out << "\t" << "POP AX" << endl;
					asm2out << "\t" << "LEA SI," << symbol->name << endl;
					asm2out << "\t" << "ADD SI, AX" << endl;
					asm2out << "\t" << "ADD SI, AX" << endl;
					asm2out << "\t" << "MOV AX, [SI]" << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "ADD AX, 1" << endl;
					asm2out << "\t" << "MOV [SI], AX" << endl;
				}
				else{
					asm2out << "\t" << "MOV AX, " << symbol->name << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "ADD AX,1" << endl;
					asm2out << "\t" << "MOV "<< symbol->name << ", AX" << endl;
					
				}
			}
			else{
				if(symbol->isArray){
					expression(node->childList[0]->childList[2]);
					asm2out << "\tPOP BX" << endl;

					/*		Now Multiply	*/
					asm2out << "\tMOV AX, 2" << endl;
					asm2out << "\t" << "CWD" << endl;
					asm2out << "\t" << "IMUL BX" << endl;
					asm2out << "\tMOV BX, AX" << endl;
					asm2out << "\tADD BX," << symbol->offset << endl;
			

					/*		Multiplication ends		*/
			
					asm2out << "\t" << "PUSH DI" << endl;
					asm2out << "\t" << "MOV DI, BX" << endl;	
					asm2out << "\t" << "NEG DI" << endl;		
					asm2out << "\t" << "MOV AX, [BP+DI]" << endl;
					asm2out << "\t" << "MOV DX, AX" << endl;
					asm2out << "\t" << "ADD AX, 1" << endl;
					asm2out << "\t" << "MOV [BP+DI], AX" << endl;
					asm2out << "\t" << "POP DI" << endl;
					asm2out << "\t" << "PUSH DX" << endl;
				}
				else{
					asm2out << "\t" << "MOV AX, [BP- " << symbol->offset << "]" << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "ADD AX, 1" << endl;
					asm2out << "\t" << "MOV [BP- " << symbol->offset << "], AX" << endl;
					
				}
			}
		}
		else if(node->childList[1]->type == "DECOP"){
			/*		factor : variable DECOP		*/
			
			SymbolInfo* symbol = table2->lookUp(node->childList[0]->childList[0]->name);
			//table->print(asm2out);
			if(symbol->isGlobal){
				if(symbol->isArray){
					expression(node->childList[0]->childList[2]);
					asm2out << "\t" << "POP AX" << endl;
					asm2out << "\t" << "LEA SI," << symbol->name << endl;
					asm2out << "\t" << "ADD SI, AX" << endl;
					asm2out << "\t" << "ADD SI, AX" << endl;
					asm2out << "\t" << "MOV AX, [SI]" << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "SUB AX, 1" << endl;
					asm2out << "\t" << "MOV [SI], AX" << endl;
				}
				else{
					asm2out << "\t" << "MOV AX, " << symbol->name << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "SUB AX, 1" << endl;
					asm2out << "\t" << "MOV "<< symbol->name << ", AX" << endl;
				}
			}
			else{
				if(symbol->isArray){
					expression(node->childList[0]->childList[2]);
					asm2out << "\tPOP BX" << endl;

					/*		Now Multiply	*/
					asm2out << "\tMOV AX, 2" << endl;
					asm2out << "\t" << "CWD" << endl;
					asm2out << "\t" << "IMUL BX" << endl;
					asm2out << "\tMOV BX, AX" << endl;
					asm2out << "\tADD BX, " << symbol->offset << endl;
			

					/*		Multiplication ends		*/
			
					asm2out << "\t" << "PUSH DI" << endl;
					asm2out << "\t" << "MOV DI, BX" << endl;	
					asm2out << "\t" << "NEG DI" << endl;		
					asm2out << "\t" << "MOV AX, [BP+DI]" << endl;
					asm2out << "\t" << "MOV DX, AX" << endl;
					asm2out << "\t" << "SUB AX, 1" << endl;
					asm2out << "\t" << "MOV [BP+DI], AX" << endl;
					asm2out << "\t" << "POP DI" << endl;
					asm2out << "\t" << "PUSH DX" << endl;

				}
				else{
					asm2out << "\t" << "MOV AX, [BP- " << symbol->offset << "]" << endl;
					asm2out << "\t" << "PUSH AX" << endl;
					asm2out << "\t" << "SUB AX, 1" << endl;
					asm2out << "\t" << "MOV [BP- " << symbol->offset << "], AX" << endl;
					
				}
			}
		}
	}
	else if(node->childList[0]->type == "ID"){
		/*		factor : ID LPAREN argument_list RPAREN		*/
		argument_list(node->childList[2]);
		asm2out << "\t" << "CALL " << node->childList[0]->name << endl;
		/*			newly added		*/

		SymbolInfo* symbol = table->lookUp(node->childList[0]->name);
		//asm2out << "\t" << "ADD SP, " << (symbol->paramList.size()) * 2 << endl;		//newly added line

		/*							*/
		asm2out << "\t" << "PUSH CX" << endl;
	}
	else if(node->childList[0]->type == "LPAREN"){
		/*		factor : LPAREN expression RPAREN		*/
		expression(node->childList[1]);
	}
	else if(node->childList[0]->type == "CONST_INT"){
		/*		factor : CONST_INT		*/
		
		asm2out << "\t\t" << ";Line no# " << node->startLine << ": CONST_INT " << endl;
		asm2out << "\t" << "MOV AX, " << stoi(node->childList[0]->name) << endl;
		asm2out << "\t" << "PUSH AX" << endl;
	}
	else if(node->childList[0]->type == "CONST_FLOAT"){
		/*		factor : CONST_FLOAT		*/
	}
}


void argument_list(SymbolInfo* node){
	/*		argument_list : arguments		*/
	if(node->childList.size()==1){
		arguments(node->childList[0]);
	}
}


void arguments(SymbolInfo* node){
	if(node->childList.size()==3){
		/*		arguments : arguments COMMA logic_expression		*/
		logic_expression(node->childList[2]);
		arguments(node->childList[0]);

	}
	else if(node->childList.size()==1){
		/*		arguments : logic_expression		*/
		logic_expression(node->childList[0]);
	}
	
}


void enter_new_scope(SymbolInfo* node){
	table2->enterScope();
}





/*		ICG non-terminal function portion ends			*/




/*		To print Parse Tree		*/
void printParseTree(SymbolInfo* si,int depth){

	/*		To Print Spaces		*/
	for(int i=1;i<=depth;i++){
		treeout << " " ;
	}

	if(si->isLeaf){
		treeout << si->type << " : "<< si->name <<"\t"<<"<Line: "<<si->startLine<<">"<<endl;
	}
	else{
		treeout << si->type << " : "<< si->name <<" \t"<<"<Line: "<<si->startLine<<"-"<<si->endLine<<">"<< endl;
	}
	
	for(int i=0; i < si->childList.size(); i++){
		printParseTree(si->childList[i],depth+1);
	}

}



/*	 To insert a function to the global scope	*/

void insert_function_to_global_scope(SymbolInfo* func,SymbolInfo* typeSpecifier,bool isParameterPresent){
	func->isFunction = true;
	func->varType = typeSpecifier->name;
	for(int i=0; i < params.size(); i++){
		func->paramList.push_back(params[i]);		//Update function's parameters list
	}


	bool flag = table->insert(*(func));
	if(!flag){
		/* 	Found another one like this
			Could be  a declaration
			Or multiple declaration error
		*/
		SymbolInfo* tempSi = table->lookUp(func->name);

		if(!(tempSi->isFunction)){
			/*		Multiple declaration but previous one is not a function		*/
			errorout << "Line# " << line_count << ": \'" << func->name << "\' redeclared as different kind of symbol"<<endl;
			errorCount++;
		}
		else{
			if(tempSi->isFunctionDefined){
				if(tempSi->varType != func->varType){
					/*	 Conflicting return types error found	*/
					errorout << "Line# "<<line_count<<": Conflicting types for \'" << func->name << "\'" <<endl;
					errorCount++;
				}
				else{
					/*		Multiple Definition 		*/
					errorout << "Line# "<<line_count << ": Multiple definition of function \'"<< func->name <<"\'" <<endl;
					errorCount++;
				}
			}
			else{
				if(tempSi->varType != func->varType){
					/*		Return Type Mismatch	*/
					errorout << "Line# "<< line_count << ": Conflicting types for \'" << func->name <<"\'"<< endl;
					errorCount++;
				}	

				if(tempSi->paramList.size() != func->paramList.size()){
					/* 		Number of function input parameters doesn't match		*/
					errorout << "Line# " << line_count << ": Conflicting types for \'"<< func->name << "\'"<<endl;
					errorCount++;
				}
				else{
					bool flag1 = false;
					for(int i=0; i<tempSi->paramList.size(); i++){
						/*		Updating parameters' names 		*/
						tempSi->paramList[i]->name = func->paramList[i]->name;
						tempSi->paramList[i]->type = func->paramList[i]->type;

						if(tempSi->paramList[i]->varType != func->paramList[i]->varType){
							/*	For error like this
								declaration: void foo(int a, int b);
								definition:  void foo(int a, float b);
							*/
							flag1 =  true;
							errorout << "Line# " << line_count << ": Type specifier mismatch for the "<<i+1<<"th parameter with declaration of the function \'" << func->name << "\'" << endl;
							errorCount++;
						}
					}
					if(!flag1){
						tempSi->isFunctionDefined = true;
					}
				}
			}
		}
	}
	else{
		func->isFunctionDeclared = false;		//Function is not been declared before
		func->isFunctionDefined = true;

		/*
			Check if void foo(int a,int) exists or not
		*/
		if(isParameterPresent){
			for(int i=0; i < func->paramList.size(); i++){
				if(func->paramList[i]->name == "dummy_name"){
					errorout << "Line# " << line_count << ": Parameter Name missing"<<endl;
					errorCount++;
				}
			}
		}
	}
}

void yyerror(char *s)
{
	
}



%}


%union{
	SymbolInfo* symbolInfo;
}

%token<symbolInfo> IF ELSE LOWER_THAN_ELSE FOR WHILE DO BREAK CHAR DOUBLE RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN 
%token<symbolInfo> INCOP DECOP ASSIGNOP BITOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON

%token<symbolInfo> ID VOID INT FLOAT MULOP ADDOP RELOP LOGICOP CONST_INT CONST_FLOAT ERROR_FLOAT

%type<symbolInfo> start program unit func_declaration func_definition parameter_list compound_statement
%type<symbolInfo> var_declaration type_specifier declaration_list statements statement expression_statement 
%type<symbolInfo> variable expression logic_expression rel_expression simple_expression term unary_expression 
%type<symbolInfo> factor argument_list arguments
%type<symbolInfo> enter_new_scope



%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		//write your code in this block in all the similar blocks below

		logout << "start : program" <<endl;
		$$ = new SymbolInfo("program","start");		
		$$->startLine = $1->startLine;		
		$$->endLine = $1->endLine;
		$$->childList.push_back($1);
		startNode = $$;

		printParseTree($$,0);

		/*		ICG portion starts		*/

		// asm1out << ".MODEL SMALL" << endl;
		// asm1out << ".STACK 1000H" << endl;
		// asm1out << ".Data" << endl;
		// asm1out << "\t" << "CR EQU 0DH" << endl;
		// asm1out << "\t" << "LF EQU 0AH" << endl;
		// asm1out << "\t" << "number DB \"00000$\"" << endl;

		for(int i=0; i<globalVar.size(); i++){
			if(globalVar[i]->isArray){
				//My_Array DB 100 DUP(?)
				//asm1out << "\t" << globalVar[i]->name << " DW "<< globalVar[i]->arraySize <<" DUP (0000H)" <<endl;
			}
			else{
				//asm1out << "\t" << globalVar[i]->name << " DW 1 DUP (0000H)" <<endl;
			}
		}

		//asm1out << ".CODE" << endl;

		/*		ICG portion ends		*/

	}
	;

program : program unit 
	{
		logout << "program : program unit" << endl;
		$$ = new SymbolInfo("program unit","program");		
		$$->startLine = $1->startLine;		
		$$->endLine = $2->endLine;
		$$->childList.push_back($1);
		$$->childList.push_back($2);
	}
	| unit
	{
		logout << "program : unit" <<endl;
		$$ = new SymbolInfo("unit","program");		
		$$->startLine = $1->startLine;		
		$$->endLine = $1->endLine;
		$$->childList.push_back($1);
	}
	;
	
unit : var_declaration
	{
		logout << "unit : var_declaration" <<endl;
		$$ = new SymbolInfo("var_declaration","unit");		
		$$->startLine = $1->startLine;		
		$$->endLine = $1->endLine;
		$$->childList.push_back($1);
	}
     | func_declaration
	 {
		logout << "unit : func_declaration" << endl;
		$$ = new SymbolInfo("func_declaration","unit");
		$$->startLine = $1->startLine;		
		$$->endLine = $1->endLine;
		$$->childList.push_back($1);
	 }
     | func_definition
	 {
		logout << "unit : func_definition" << endl;
		$$ = new SymbolInfo("func_definition","unit");
		$$->startLine = $1->startLine;		
		$$->endLine = $1->endLine;
		$$->childList.push_back($1);
	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			logout << "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN parameter_list RPAREN SEMICOLON","func_declaration");
			$$->startLine = $1->startLine;		
			$$->endLine = $6->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
			$$->childList.push_back($5);
			$$->childList.push_back($6);

			for(int i=0; i < params.size(); i++){
				$2->paramList.push_back(params[i]);		//Update function's parameters list
			}

			params.clear();								//Clear the global params vector 

			bool flag = table->insert(*($2));
			if(!flag){
				/*		Multiple Declaration		*/
				errorout << "Line# "<<line_count<<": Multiple declaration of function \'"<<$2->name<<"\'"<<endl;
				errorCount++;
			}
			else{
				/*		Function is now successfully declared		*/
				$2->isFunction = true;
				$2->isFunctionDeclared = true;
				$2->varType = $1->name;
			}

		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			logout << "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN RPAREN SEMICOLON","func_declaration");
			$$->startLine = $1->startLine;		
			$$->endLine = $5->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
			$$->childList.push_back($5);

			params.clear();								//Clear the global params vector 

			bool flag = table->insert(*($2));
			if(!flag){
				/*		Multiple Declaration		*/
				errorout << "Line# "<<line_count<<": Multiple declaration of function \'"<<$2->name<<"\'"<<endl;
				errorCount++;
			}
			else{
				/*		Function is now successfully declared		*/
				$2->isFunction = true;
				$2->isFunctionDeclared = true;
				$2->varType = $1->name;
			}
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
					isFunction = true;								//Definition could be a valid function
					insert_function_to_global_scope($2,$1,true);	//first insert this function to the global scope\
																	function paramater list is present,so 3rd parameter is true		

					/*		ICG portion starts		*/
					
					offset = 0;									//Reset offset count
					
					//temp1out << ";Line no# " << line_count <<": " << $2->name << " starts" << endl;							
					//temp1out << $2->name << " PROC" << endl;
					if($2->name == "main"){
						//temp1out << "\tMOV AX, @DATA" << endl;
						//temp1out << "\tMOV DS, AX"  << endl;
					}
					// temp1out << "\t" << "PUSH BP" << endl;
					// temp1out << "\t" << "MOV BP, SP" << endl;
					currentLabel = newLabel();					//Generate new label

					/*		ICG portion ends		*/									
				} compound_statement
		{
			logout << "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN parameter_list RPAREN compound_statement","func_definition");
			$$->startLine = $1->startLine;		
			$$->endLine = $7->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
			$$->childList.push_back($5);
			$$->childList.push_back($7);

			/*		Function Definition is done.Now clear all the global vars		*/
			params.clear();
			isFunction = false;


			/*		ICG portion starts		*/
				// temp1out << currentLabel << ":" << endl;
				// temp1out << "\tADD SP, " << offset << endl;
				// temp1out << "\t" << "POP BP" << endl;
				if($2->name != "main"){
					//temp1out << "\t" << "RET" << endl;
				}
				else{
					// temp1out << "\tMOV AX, 4CH" << endl;
					// temp1out << "\tINT 21H" << endl;
				}
				// temp1out << $2->name << " ENDP" <<endl;
				// temp1out << ";Line no# " << line_count <<": " << $2->name << " ends" << endl;

				offset = 0;			//reset offset

			/*		ICG portion ends		*/

		}
		| type_specifier ID LPAREN RPAREN {
					isFunction = true;								//Definition could be a valid function
					insert_function_to_global_scope($2,$1,false);	//first insert this function to the global scope\
																	function paramater list is absent,so 3rd parameter is false	

					/*		ICG portion starts		*/
					
					offset = 0;										//Reset offset count

					currentLabel = newLabel();
					// temp1out << ";Line no# " << line_count <<": " << $2->name << " starts" << endl;
					// temp1out << $2->name << " PROC" << endl;
					if($2->name == "main"){
						// temp1out << "\tMOV AX, @DATA" << endl;
						// temp1out << "\tMOV DS, AX"  << endl;
					}
					// temp1out << "\t" << "PUSH BP" << endl;
					// temp1out << "\t" << "MOV BP, SP" << endl;

					/*		ICG portion ends		*/													
				} compound_statement
		{
			logout << "func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN RPAREN compound_statement","func_definition");
			$$->startLine = $1->startLine;		
			$$->endLine = $6->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
			$$->childList.push_back($6);

			/*		Function Definition is done.Now clear all the global vars		*/
			params.clear();
			isFunction = false;


			/*		ICG portion starts		*/

				// temp1out << currentLabel << ":" << endl;
				// temp1out << "\tADD SP, " << offset << endl;
				// temp1out << "\t" << "POP BP" << endl;
				if($2->name != "main"){
					//temp1out << "\t" << "RET" << endl;
				}
				else{
					//temp1out << "\tMOV AX, 4CH" << endl;
					//temp1out << "\tINT 21H" << endl;
				}
				// temp1out << $2->name << " ENDP" <<endl;
				// temp1out << ";Line no# " << line_count <<": " << $2->name << " ends" << endl;

				offset = 0;				//reset offset

			/*		ICG portion ends		*/


		}
		| type_specifier ID LPAREN error {
					if(!errorFlag){
						errorFlag = true;		//so that it doesn't get caught in this error again
						errorout << "Line# " << line_count << ": Syntax error at parameter list of function definition" << endl;
						errorCount++;

						params.clear();			//Clear the global parameter list to discard all the wrong params which were inserted
					}
				} RPAREN compound_statement 
		{
			logout << "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl;
			$$ = new SymbolInfo("type_specifier ID LPAREN parameter_list RPAREN compound_statement","func_definition");
			$$->startLine = $1->startLine;		
			$$->endLine = $7->endLine;

			/*		
					Create a new rule for printing parse tree for the corrupted parameter list
			*/
			SymbolInfo* tempSi = new SymbolInfo("error","parameter_list");
			tempSi->startLine = $3->endLine;
			tempSi->endLine = $6->startLine;
			tempSi->isLeaf = true;

			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back(tempSi);
			$$->childList.push_back($6);
			$$->childList.push_back($7);

			/*		Function Definition is done.Now clear all the global vars		*/
			params.clear();
			isFunction = false;
			errorFlag = false;			//To catch next error
		}
 		;				

parameter_list  : parameter_list COMMA type_specifier ID
		{
			logout << "parameter_list  : parameter_list COMMA type_specifier ID" << endl;
			$$ = new SymbolInfo("parameter_list COMMA type_specifier ID","parameter_list");
			$$->startLine = $1->startLine;		
			$$->endLine = $4->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);

			$4->varType = $3->name ;					//setting variable type of that identifier(INT,FLOAT etc) 
			params.push_back($4);
		}
		| parameter_list COMMA type_specifier
		{
			logout << "parameter_list  : parameter_list COMMA type_specifier" << endl;
			$$ = new SymbolInfo("parameter_list COMMA type_specifier","parameter_list");
			$$->startLine = $1->startLine;
			$$->endLine = $3->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);

			/*		Create a temp identifier. Example:  void foo(int dummy_id)		*/
			SymbolInfo* dummy_id = new SymbolInfo("dummy_name","dummy_type");
			dummy_id->varType = $3->name;					//setting variable type of that identifier(INT,FLOAT etc) 
			params.push_back(dummy_id);
		}
 		| type_specifier ID
		{
			logout << "parameter_list : type_specifier ID" << endl;
			$$ = new SymbolInfo("type_specifier ID","parameter_list");
			$$->startLine = $1->startLine;
			$$->endLine = $2->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);

			$2->varType = $1->name;				//setting variable type of that identifier(INT,FLOAT etc) 
			params.push_back($2);
		}
		| type_specifier
		{
			logout << "parameter_list : type_specifier" << endl;
			$$ = new SymbolInfo("type_specifier","parameter_list");
			$$->startLine = $1->startLine;
			$$->endLine = $1->endLine;
			$$->childList.push_back($1);
			
			/*		Create a temp identifier. Example:  void foo(int dummy_id)		*/
			SymbolInfo* dummy_id = new SymbolInfo("dummy_name","dummy_type");
			dummy_id->varType = $1->name;					//setting variable type of that identifier(INT,FLOAT etc) 
			params.push_back(dummy_id);
		}
 		;

 		
compound_statement : LCURL enter_new_scope statements RCURL
			{
				logout << "compound_statement : LCURL statements RCURL" << endl;
				$$ = new SymbolInfo("LCURL statements RCURL","compound_statement");
				$$->startLine = $1->startLine;
				$$->endLine = $4->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($3);
				$$->childList.push_back($4);

				/*		after this reduction, this scope should be exited		*/
				table->print(logout);
				table->exitScope();
			}
 		    | LCURL enter_new_scope RCURL
			{
				logout << "compound_statement : LCURL RCURL" << endl;
				$$ = new SymbolInfo("LCURL RCURL","compound_statement");		
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($3);

				/*		after this reduction, this scope should be exited		*/
				table->print(logout);
				table->exitScope();
			}
 		    ;

enter_new_scope : {
				/*		Enter new scope as you found a Left curl		*/
				table->enterScope();

				/*	It could be a function or it could be just a for,while loop or if else condition.
					If it is a function then its parameters should be inserted to current scope.
					isFunction =  true mans that current reduction is a function definition.
				*/
				if(isFunction){
					for(int i=0; i<params.size(); i++){
						bool flag = table->insert(*(params[i]));
						if(!flag){
							SymbolInfo* tempSi = table->lookUp(params[i]->name);

							if(tempSi->varType != params[i]->varType){
								/*		Conflicting return/parameter type error		*/
								errorout<<"Line# "<<line_count<<": Conflicting types for \'" << params[i]->name <<"\'" <<endl;
								errorCount++;
							}
							else{
								/*		Found Multiple declaration Error		*/
								errorout<<"Line# "<<line_count<<": Redefinition of parameter \'"<<params[i]->name<<"\'"<<endl;
								errorCount++;
							}
							
						}
					}
				}
			}
			;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			logout << "var_declaration : type_specifier declaration_list SEMICOLON" << endl;
			$$ = new SymbolInfo("type_specifier declaration_list SEMICOLON","var_declaration");		
			$$->startLine = $1->startLine;		
			$$->endLine = $3->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);

			if($1->name == "VOID"){
				errorout << "Line# "<<line_count << ": Variable or field ";
				for(int i=0; i < $2->decList.size(); i++){
					errorout << "\'"<< $2->decList[i]->name <<"\' ";
				}
				errorout << "declared void " << endl;
				errorCount++;
			
			}
			else{
				for(int i=0; i < $2->decList.size(); i++){
					if($2->decList[i]->varType == "ARRAY"){
						$2->decList[i]->varType = $1->name + "_ARRAY";
					}
					else{
						$2->decList[i]->varType = $1->name;
					}

					bool flag = table->insert(*($2->decList[i]));

					if(!flag){
						SymbolInfo* tempSi = table->lookUp($2->decList[i]->name);

						if(tempSi->varType != $2->decList[i]->varType){
							/*			Type Conflict Error.Example: int a;float a		*/
							errorout << "Line# "<< line_count << ": Conflicting types for \'" << $2->decList[i]->name << "\'" <<endl;
							errorCount++;
						}
						else{
							/*			Multiple Declaration. Example: int a;int a		*/
							errorout <<"Line# "<< line_count<< ": Redifinition of parameter \'"<<$2->decList[i]->name<<"\'"<<endl;
							errorCount++;
						}
					} 
				}
			}
		}
		| type_specifier error {
					if(!errorFlag){
						errorFlag = true;		//so that it doesn't get caught in this error again
						errorout << "Line# " << line_count << ": Syntax error at declaration list of variable declaration" << endl;
						errorCount++;

						params.clear();			//Clear the global parameter list to discard all the wrong params which were inserted
					}
				} SEMICOLON
		{
			logout << "var_declaration : type_specifier declaration_list SEMICOLON" << endl;
			$$ = new SymbolInfo("type_specifier declaration_list SEMICOLON","var_declaration");
			$$->startLine = $1->startLine;		
			$$->endLine = $4->endLine;

			/*		
					Create a new rule for printing parse tree for the corrupted declaration list
			*/
			SymbolInfo* tempSi = new SymbolInfo("error","declaration_list");
			tempSi->startLine = $1->endLine;
			tempSi->endLine = $4->startLine;
			tempSi->isLeaf = true;

			$$->childList.push_back($1);
			$$->childList.push_back(tempSi);
			$$->childList.push_back($4);

			/*		Function Definition is done.Now clear all the global vars		*/
			params.clear();
			isFunction = false;
			errorFlag = false;			//To catch next error
		}
 		 ;
 		 
type_specifier	: INT
		{
			logout << "type_specifier : INT"<<endl;
			$$ = new SymbolInfo("INT","type_specifier");
			$$->startLine = $1->startLine;		
			$$->endLine = $1->endLine;
			$$->childList.push_back($1);
		}
 		| FLOAT
		{
			logout << "type_specifier : FLOAT"<<endl;
			$$ = new SymbolInfo("FLOAT","type_specifier");
			$$->startLine = $1->startLine;		
			$$->endLine = $1->endLine;
			$$->childList.push_back($1);
		}
 		| VOID
		{
			logout << "type_specifier : VOID"<<endl;
			$$ = new SymbolInfo("VOID","type_specifier");
			$$->startLine = $1->startLine;		
			$$->endLine = $1->endLine;
			$$->childList.push_back($1);
		}
 		;
 		
declaration_list : declaration_list COMMA ID
		{
			logout << "declaration_list : declaration_list COMMA ID"<<endl;
			$$ = new SymbolInfo("declaration_list COMMA ID","declaration_list");
			$$->startLine = $1->startLine;		
			$$->endLine = $3->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);

			$$->decList = $1->decList;
			$$->decList.push_back($3);		//update params list


			/*			ICG portion starts		*/
			
			$3->isArray = false;
			if(table->currentScopeNo() == 1){
				/*		If it's a global array then		*/
				$3->isGlobal = true;			//update symbolinfo
				globalVar.push_back($3);
			}
			else{
				offset += 2;
				$3->offset = offset;
				//temp1out << "\t" << "SUB SP, 2" << endl;
			}

			/*			ICG portion ends		*/


		}
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
		  {
				logout << "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE"<<endl;
				$$ = new SymbolInfo("declaration_list COMMA ID LSQUARE CONST_INT RSQUARE","declaration_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $6->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);

				
				$$->decList = $1->decList;				//update declaration list
				$3->varType = "ARRAY";					//cuz thew variable is an array
				$$->decList.push_back($3);


				/*			ICG portion starts		*/
			
				$3->isArray = true;
				$3->arraySize = stoi($5->name);

				if(table->currentScopeNo() == 1){
					/*		If it's a global array then		*/
					$3->isGlobal = true;		//Update symbolinfo
					globalVar.push_back($3);
				}
				else{
					offset += (2 * ($3->arraySize));
					$3->offset = offset;
					//temp1out << "\t" << "SUB SP, " << (2 * ($3->arraySize)) << endl;
				}

				/*			ICG portion ends		*/


		  }
		  | declaration_list COMMA ID LSQUARE CONST_FLOAT RSQUARE
		  {
				/*		Generate error message if the index of an array is not an integer		*/
				logout << "declaration_list : declaration_list COMMA ID LSQUARE CONST_FLOAT RSQUARE"<<endl;
				$$ = new SymbolInfo("declaration_list COMMA ID LSQUARE CONST_FLOAT RSQUARE","declaration_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $6->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);


				/*		Well it's an error ,cuz array index cant be float		*/
				errorout << "Line# " << line_count << ": Array subscript is not an integer" <<endl;
				errorCount++;

				/*			Why am i pushing this? IDK		*/
				$$->decList = $1->decList;				//update declaration list
				$3->varType = "ARRAY";					//cuz thew variable is an array
				$$->decList.push_back($3);
		  }
 		  | ID
		  {
				logout << "declaration_list : ID"<<endl;
				$$ = new SymbolInfo("ID","declaration_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->decList.push_back($1);

				/*			ICG portion starts		*/
			
				$1->isArray = false;
				if(table->currentScopeNo() == 1){
				/*		If it's a global array then		*/
					$1->isGlobal = true;		//update symbolinfo
					globalVar.push_back($1);
				}
				else{
					offset += 2;
					$1->offset = offset;
					//temp1out << "\t" << "SUB SP, 2" << endl;
				}

				/*			ICG portion ends		*/

		  }
 		  | ID LSQUARE CONST_INT RSQUARE
		  {
				logout << "declaration_list : ID LSQUARE CONST_INT RSQUARE"<<endl;
				$$ = new SymbolInfo("ID LSQUARE CONST_INT RSQUARE","declaration_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $4->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
		
				
				$1->varType = "ARRAY";					//cuz thew variable is an array
				$$->decList.push_back($1);


				/*			ICG portion starts		*/
			
				$1->isArray = true;
				$1->arraySize = stoi($3->name);
				if(table->currentScopeNo() == 1){
					/*		If it's a global array then		*/
					$1->isGlobal = true; 		//Update Symbolinfo
					globalVar.push_back($1);
				}
				else{
					offset += (2 * ($3->arraySize));
					$1->offset = offset;
					//temp1out << "\t" << "SUB SP, " << (2 * ($1->arraySize)) << endl;
				}

				/*			ICG portion ends		*/


		  }
		  |	ID LSQUARE CONST_FLOAT RSQUARE
		  {
				/*		Generate error message if the index of an array is not an integer		*/
				logout << "declaration_list : ID LSQUARE CONST_FLOAT RSQUARE"<<endl;
				$$ = new SymbolInfo("ID LSQUARE CONST_FLOAT RSQUARE","declaration_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $4->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
		
				/*		Well it's an error ,cuz array index cant be float		*/
				errorout << "Line# " << line_count << ": Array subscript is not an integer" <<endl;
				errorCount++;

				/*			Why am i pushing this? IDK		*/
				$1->varType = "ARRAY";					//cuz thew variable is an array
				$$->decList.push_back($1);
		  }
 		  ;
 		  
statements : statement
		{
				logout << "statements : statement"<<endl;
				$$ = new SymbolInfo("statement","statements");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
		}
	   | statements statement
	   {
				logout << "statements : statements statement"<<endl;
				$$ = new SymbolInfo("statements statement","statements");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
	   }
	   ;
	   
statement : var_declaration
		{
				logout << "statement : var_declaration"<<endl;
				$$ = new SymbolInfo("var_declaration","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
		}
	  | expression_statement
	  {
				logout << "statement : expression_statement"<<endl;
				$$ = new SymbolInfo("expression_statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
	  }
	  | compound_statement
	  {
				logout << "statement : compound_statement"<<endl;
				$$ = new SymbolInfo("compound_statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
	  }
	  | func_declaration
	  {
				/*			Can't declare a function inside another function.Error.....		*/
				logout << "statement : func_declaration"<<endl;
				$$ = new SymbolInfo("func_declaration","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				errorout << "Line# " <<line_count << ": Function can't be declared inside another function" <<endl;
				errorCount++;
	  }
	  | func_definition
	  {
				/*			Can't define a function inside another function.Error.......		*/
				logout << "statement : func_definition"<<endl;
				$$ = new SymbolInfo("func_definition","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				errorout << "Line# " << line_count << ": Function can't be defined inside another function" <<endl;
				errorCount++;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
				logout << "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;
				$$ = new SymbolInfo("FOR LPAREN expression_statement expression_statement expression RPAREN statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $7->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
				$$->childList.push_back($7);
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
				logout << "statement : IF LPAREN expression RPAREN statement"<<endl;
				$$ = new SymbolInfo("IF LPAREN expression RPAREN statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $5->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);

	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
				logout << "statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;
				$$ = new SymbolInfo("IF LPAREN expression RPAREN statement ELSE statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $7->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
				$$->childList.push_back($7);
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
				logout << "statement : WHILE LPAREN expression RPAREN statement"<<endl;
				$$ = new SymbolInfo("WHILE LPAREN expression RPAREN statement","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $5->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
				logout << "statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
				$$ = new SymbolInfo("PRINTLN LPAREN ID RPAREN SEMICOLON","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $5->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);

				/*		We have to check the variable inside the printf function is declared or not		*/
				SymbolInfo* tempSi = table->lookUp($3->name);
				if(tempSi == NULL){
					/*		variable wasn't declared before.Error...		*/
					errorout << "Line# " << line_count << ": Undeclared variable \'" << $3->name << "\'" <<endl;
					errorCount++;
				}


				/*		ICG portion starts		*/
				SymbolInfo* symbol = table->lookUp($3->name);
				if(symbol->isGlobal){
					//temp1out << "\tMOV AX, " << symbol->name << endl;
				}
				else{
					//temp1out << "\tMOV AX, [BP- " << symbol->offset << "]" << endl;
				}
				
				//temp1out << "\tCALL print_output" << endl;
				//temp1out << "\tCALL new_line" << endl;

				/*		ICG portion ends		*/

	  }
	  | RETURN expression SEMICOLON
	  {
				logout << "statement : RETURN expression SEMICOLON"<<endl;
				$$ = new SymbolInfo("RETURN expression SEMICOLON","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
	  }
	  | RETURN SEMICOLON
	  {
				/*			For void functions
							return; is also valid
				*/
				logout << "statement : RETURN SEMICOLON"<<endl;
				$$ = new SymbolInfo("RETURN SEMICOLON","statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
	  }
	  ;
	  
expression_statement : SEMICOLON	
		{
				logout << "expression_statement : SEMICOLON"<<endl;
				$$ = new SymbolInfo("SEMICOLON","expression_statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
		}		
			| expression SEMICOLON 
			{
				logout << "expression_statement : expression SEMICOLON"<<endl;
				$$ = new SymbolInfo("expression SEMICOLON","expression_statement");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
			}
			| error{
					if(!errorFlag){
						errorFlag = true;		//so that it doesn't get caught in this error again
						errorout << "Line# " << line_count << ": Syntax error at expression of expression statement" << endl;
						errorCount++;
						errorLine = line_count;
						params.clear();			//Clear the global parameter list to discard all the wrong params which were inserted
					}
				} SEMICOLON
			{
				logout << "expression_statement : expression SEMICOLON" << endl;
				$$ = new SymbolInfo("expression SEMICOLON","expression_statement");
				$$->startLine = errorLine;		
				$$->endLine = $3->endLine;

				/*		
						Create a new rule for printing parse tree for the corrupted declaration list
				*/
				SymbolInfo* tempSi = new SymbolInfo("error","expression");
				tempSi->startLine = errorLine;
				tempSi->endLine = $3->startLine;
				tempSi->isLeaf = true;

				$$->childList.push_back(tempSi);
				$$->childList.push_back($3);

				/*		Function Definition is done.Now clear all the global vars		*/
				params.clear();
				isFunction = false;
				errorFlag = false;			//To catch next error
			}
			;
	  
variable : ID 		
			{
				logout << "variable : ID"<<endl;
				$$ = new SymbolInfo("ID","variable");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				/*		First we have to look for its declaration.
						So search in the scopetable
				*/
				SymbolInfo* tempSi  = table->lookUp($1->name);

				if(tempSi == NULL){
					/*		isn't declared yet.Throw Error...		*/
					errorout << "Line# " << line_count << ": Undeclared variable \'"<< $1->name << "\'" <<endl;
					errorCount++;

					$$->varType = "NULL";		//This is for typecasting and error checking for later
				}
				else{
					/*		So The variable is declared before.
							Now we have to check if it was declared as an array or not
					*/

					if(tempSi->varType == "FLOAT_ARRAY" || tempSi->varType == "INT_ARRAY"){
						/*		That means it was declared as an array..
								But ours is a normal variable.
								So ,throw an error
						*/
						//errorout << "Line# " << line_count << ": \'" << $1->name << "\' is an array" << endl;
						//errorCount++;

						$$->varType = tempSi->varType;		//This is for typecasting and error checking for later
					}
					else{
						$$->varType = tempSi->varType;		//This is for typecasting and error checking for later
					}

				}



				/*		ICG portion starts		*/

				SymbolInfo* symbol = table->lookUp($1->name);
				if(symbol->isGlobal){
					// temp1out << "\t\t" << ";Line no# " << line_count << ": ***		pushing global variable to stack		*** " << endl;
					// temp1out << "\t" << "MOV AX, " << symbol->name << endl;
					// temp1out << "\t" << "PUSH AX" << endl;
				}
				else{
					// temp1out << "\t\t" << ";Line no# " << line_count << ": ***		pushing local variable to stack		*** " << endl;
					// temp1out << "\t" << "MOV AX, [BP- " << symbol->offset << "]" << endl;
					// temp1out << "\t" << "PUSH AX" << endl;
				}

				/*		ICG portion ends		*/

			}
	 | ID LSQUARE expression RSQUARE 
	 {
			logout << "variable : ID LSQUARE expression RSQUARE"<<endl;
			$$ = new SymbolInfo("ID LSQUARE expression RSQUARE","variable");
			$$->startLine = $1->startLine;		
			$$->endLine = $4->endLine;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);

			/*		First we have to look for its declaration.
					So search in the scopetable
			*/
			SymbolInfo* tempSi  = table->lookUp($1->name);

			if(tempSi == NULL){
				/*		isn't declared yet.Throw Error...		*/
				errorout << "Line# " << line_count << ": Undeclared variable \'"<< $1->name << "\'" <<endl;
				errorCount++;

				$$->varType = "NULL";		//This is for typecasting and error checking for later
			}
			else{
				/*		So The variable is declared before.
						Now we have to check if it was declared as an array or not
				*/
				if(tempSi->varType == "FLOAT" || tempSi->varType == "INT"){
					/*		That means it was declared as a normal variable..
							But ours is an array..
							So ,throw an error...
					*/
					errorout << "Line# " << line_count << ": \'" << $1->name << "\' is not an array" << endl;
					errorCount++;

					$$->varType = "NULL";		//This is for typecasting and error checking for later
				}
				else{
					$$->varType = tempSi->varType;		//This is for typecasting and error checking for later
				}

			}
			
			/*		Check for Valid Array Indexing		*/
			if($3->varType != "INT"){
				errorout << "Line# " << line_count << ": Array subscript is not an integer" << endl;
				errorCount++;
			}

	 }
	 ;
	 
 expression : logic_expression	
		{
				logout << "expression : logic_expression"<<endl;
				$$ = new SymbolInfo("logic_expression","expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
		}
	   | variable ASSIGNOP logic_expression 	
	   {		logout << "expression : variable ASSIGNOP logic_expression"<<endl;
				$$ = new SymbolInfo("variable ASSIGNOP logic_expression","expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);


				/*		This is for type Checking.
						Generate an error message if operands of an operator are not consistent with each other
				*/

				if(($1->varType == "INT" || $1->varType == "INT_ARRAY") && ($3->varType == "INT_ARRAY" || $3->varType == "INT")){
					/*
							Example: a = b[5];
									a = b;
									a[4] = b;
									a[4] = b[4];
							No Problem
					*/
					$$->varType = "INT";		//This is for type checking and error handling for later
				}
				if(($1->varType == "FLOAT" || $1->varType == "FLOAT_ARRAY") && ($3->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT" || $3->varType =="INT" || $3->varType == "INT_ARRAY")){
					/*
							Example:float a,b[10];
									int c,d[10];
									a = b[5]; 
									a = b[5];
									a = b;
									a[4] = b;
									a[4] = b[4];
									a = c;
									a = d[4];
							No Problem
					*/
					$$->varType = "FLOAT";		//This is for type checking and error handling for later
				}
				if(($1->varType == "INT" || $1->varType == "INT_ARRAY") && ($3->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT")){
					/*
							Example: float a.b[10];
									int c,d[10];
									a = c;
									b[2] = c;
									a = d[2];
									b[2] = d[2];
							Possible Data loss.
							Generate a Warning message
					*/
					errorout << "Line# " << line_count << ": Warning: possible loss of data in assignment of FLOAT to INT" << endl;

					$$->varType = "INT";		//This is for type checking and error handling for later
				}
				if($1->varType == "VOID" || $3->varType == "VOID"){
					/*
							if any of them is void then it cant be assigned.
							Throw an error
					*/
					errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
					errorCount++;

					$$->varType = "NULL";		//This is for type checking and error handling for later
				}
				if($1->varType == "NULL" || $3->varType == "NULL" || $1->varType == "" || $3->varType == ""){
					/*
							An error has been already reported...So skip
					*/
					$$->varType = "NULL";		//This is for type checking and error handling for later
				}

				/*			ICG portion starts		*/

				// temp1out << "\t" << "POP AX" << endl;
				// temp1out << "\t" << "POP BX" << endl;
				SymbolInfo* si = table->lookUp($1->childList[0]->name);
				if(si->isGlobal){
					SymbolInfo* symbol = table->lookUp($1->childList[0]->name);
					if(symbol->isArray){
						//temp1out << "\t" << "MOV " << $1->childList[0]->name << ", AX" << endl;
					}
					else{
						//temp1out << "\t" << "MOV " << $1->childList[0]->name << ", AX" << endl;
					}
				}
				else{
					SymbolInfo* symbol = table->lookUp($1->childList[0]->name);
					if(symbol->isArray){
						//temp1out << "\t" << "MOV [BP- " << symbol->offset + (2* stoi($1->childList[3]->name))  << "], AX" << endl;
					}
					else{
						//temp1out << "\t" << "MOV [BP- " << symbol->offset << "], AX" << endl;
					}
					
				}

				/*			ICG portion ends		*/

	   }
	   ;
			
logic_expression : rel_expression 
		{
				logout << "logic_expression : rel_expression" <<endl;
				$$ = new SymbolInfo("rel_expression","logic_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
		}	
		 | rel_expression LOGICOP rel_expression
		 {
				logout << "logic_expression : rel_expression LOGICOP rel_expression" <<endl;
				$$ = new SymbolInfo("rel_expression LOGICOP rel_expression","logic_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);

				if($1->varType == "VOID" || $3->varType == "VOID"){
					/*
							Expression cant have void in it.Throw an error
					*/
					errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
					errorCount++;

					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				if($1->varType == "" || $3->varType == "" || $1->varType == "NULL" || $3->varType == "NULL"){
					/*
							There was an error before.Skip this...
					*/
					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				else if($1->varType == "FLOAT" || $1->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT" || $3->varType == "FLOAT_ARRAY"){
					/*
							Show Warning: possible loss of data in assignment of FLOAT to INT
					*/
					errorout << "Line# " << line_count << ": Warning: possible loss of data in assignment of FLOAT to INT" <<endl;
					//Keep Errorcount as it is
					$$->varType = "INT";					//This is for typecasting and error checking for later
				}
				else{
					/*
							In All other cases
					*/
					$$->varType = "INT";					//This is for typecasting and error checking for later
				}
		 } 	
		 ;
			
rel_expression : simple_expression 
		{
				logout << "rel_expression : simple_expression" <<endl;
				$$ = new SymbolInfo("simple_expression","rel_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later

		}
		| simple_expression RELOP simple_expression
		{
				logout << "rel_expression : simple_expression RELOP simple_expression" << endl;
				$$ = new SymbolInfo("simple_expression RELOP simple_expression","rel_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);


				if($1->varType == "VOID" || $3->varType == "VOID"){
					/*
							Expression cant have void in it.Throw an error
					*/
					errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
					errorCount++;

					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				if($1->varType == "" || $3->varType == "" || $1->varType == "NULL" || $3->varType == "NULL"){
					/*
							There was an error before.Skip this...
					*/
					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				else if($1->varType == "FLOAT" || $1->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT" || $3->varType == "FLOAT_ARRAY"){
					/*
							Show Warning: possible loss of data in assignment of FLOAT to INT
					*/
					//errorout << "Line# " << line_count << ": Warning: possible loss of data in assignment of FLOAT to INT" <<endl;
					//Keep Errorcount as it is
					$$->varType = "INT";					//This is for typecasting and error checking for later
				}
				else{
					/*
							In All other cases
					*/
					$$->varType = "INT";					//This is for typecasting and error checking for later
				}
		}	
		;
				
simple_expression : term 
			{
				logout << "simple_expression : term" <<endl;
				$$ = new SymbolInfo("term","simple_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
			}
		  | simple_expression ADDOP term 
		  {
				logout << "simple_expression : simple_expression ADDOP term" <<endl;
				$$ = new SymbolInfo("simple_expression ADDOP term","simple_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);

				if($1->varType == "VOID" || $3->varType == "VOID"){
					/*
							Expression cant have void in it.Throw an error
					*/
					errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
					errorCount++;

					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				if($1->varType == "" || $3->varType == "" || $1->varType == "NULL" || $3->varType == "NULL"){
					/*
							There was an error before.Skip this...
					*/
					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				else if($1->varType == "FLOAT" || $1->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT" || $3->varType == "FLOAT_ARRAY"){
					/*
							Show Warning: possible loss of data in assignment of FLOAT to INT
					*/
					$$->varType = "FLOAT";					//This is for typecasting and error checking for later
				}
				else{
					/*
							In All other cases
					*/
					$$->varType = "INT";					//This is for typecasting and error checking for later
				}


				/*		ICG portion starts		*/

				// temp1out << "\t\t" << ";Line no# " << line_count << ": ***		simple_exp ADDOP term		*** " << endl;
				// temp1out << "\t" << "POP AX" << endl;
				// temp1out << "\t" << "POP BX" << endl;

				if($2->name == "+"){
					// temp1out << "\t" << "ADD AX, BX" << endl;
					// temp1out << "\t" << "PUSH AX" << endl;
				}
				else if($2->name == "-"){
					// temp1out << "\t" << "SUB BX, AX" << endl;
					// temp1out << "\t" << "PUSH BX" << endl;
				}

				/*		ICG portion ends		*/
		  }
		  ;
					
term : unary_expression
		{
				logout << "term : unary_expression" <<endl;
				$$ = new SymbolInfo("unary_expression","term");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
		}
     |  term MULOP unary_expression
		{
				logout << "term : term MULOP unary_expression" <<endl;
				$$ = new SymbolInfo("term MULOP unary_expression","term");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);

				if($2->name == "%" ){
					/*
							Both the operands of the modulus operator should be integers
					*/
					if($3->zeroFlag){
						/*
								Divided by zero error
						*/
						errorout << "Line# " << line_count <<": Warning: division by zero i=0f=1Const=0" <<endl;
						//skip errorcount increase
						$$->varType = "INT";
					}
					if(($1->varType == "INT" || $1->varType == "INT_ARRAY") && ($3->varType == "INT" || $3->varType == "INT_ARRAY")){
						/*	
							It's okay!No Problem Then
						*/
						$$->varType = "INT";				//This is for typecasting and error checking for later
					}
					else if($1->varType == "VOID" || $3->varType == "VOID"){
						/*
							Expression can't be void
						*/
						errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
						errorCount++;
						$$->varType = "NULL";				//This is for typecasting and error checking for later
					}
					else if($1->varType == "" || $3->varType == ""||$1->varType == "NULL"||$3->varType == "NULL"){
						/*
							This error was handled before.skip
						*/
					$$->varType = "NULL";				//This is for typecasting and error checking for later
					}
					else{
						/*
							Float is present..throw error
						*/
						errorout << "Line# " << line_count << ": Operands of modulus must be integers" << endl;
						errorCount++;
						$$->varType = "NULL";				//This is for typecasting and error checking for later
					}

				}
				else{
					/*
							For the other operators like /,*,
					*/
					if($2->name == "/" && $3->zeroFlag){
						/*
								Divided by zero error
						*/
						errorout << "Line# " << line_count <<": Warning: division by zero i=0f=1Const=0" <<endl;
						//skip errorcount increase
						$$->varType = "INT";
					}
					if($1->varType == "VOID" || $3->varType == "VOID"){
						/*
							Expression cant have void in it.Throw an error
						*/
						errorout << "Line# " << line_count << ": Void cannot be used in expression" << endl;
						errorCount++;

						$$->varType = "NULL";					//This is for typecasting and error checking for later
					}
					if($1->varType == "" || $3->varType == "" || $1->varType == "NULL" || $3->varType == "NULL"){
						/*
								There was an error before.Skip this...
						*/
						$$->varType = "NULL";					//This is for typecasting and error checking for later
					}
					else if($1->varType == "FLOAT" || $1->varType == "FLOAT_ARRAY" || $3->varType == "FLOAT" || $3->varType == "FLOAT_ARRAY"){
						/*
								Show Warning: possible loss of data in assignment of FLOAT to INT
						*/
						$$->varType = "FLOAT";					//This is for typecasting and error checking for later
					}
					else{
						/*
								In All other cases
						*/
						$$->varType = "INT";					//This is for typecasting and error checking for later
					}
				}


				/*		ICG portion starts		*/

					// temp1out << "\t" << "POP AX" << endl;
					// temp1out << "\t" << "POP CX" << endl;
					// temp1out << "\t" << "CWD" << endl;
					// temp1out << "\t" << "IMUL CX" << endl;
					// temp1out << "\t" << "PUSH AX" << endl;

				/*		ICG portion ends		*/

	 	}
     ;

unary_expression : ADDOP unary_expression  
		{
				logout << "unary_expression : ADDOP unary_expression" <<endl;
				$$ = new SymbolInfo("ADDOP unary_expression","unary_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);

				$$->varType = $2->varType;					//This is for typecasting and error checking for later		
		}
		 | NOT unary_expression 
		 {
				logout << "unary_expression : NOT unary_expression" <<endl;
				$$ = new SymbolInfo("NOT unary_expression","unary_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);

				$$->varType = $2->varType;					//This is for typecasting and error checking for later
		 }
		 | factor 
		 {
				logout << "unary_expression : factor" <<endl;
				$$ = new SymbolInfo("factor","unary_expression");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->zeroFlag = $1->zeroFlag;				//To handle divided by zero
				$$->varType = $1->varType;					//This is for typecasting and error checking for later
				//cout<<$$->startLine<<" unary exp : factor "<<$$->varType << endl;
		 }
		 ;
	
factor : variable 
		{
				logout << "factor : variable" <<endl;
				$$ = new SymbolInfo("variable","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
		}
	| ID LPAREN argument_list RPAREN
	{
				logout << "factor : ID LPAREN argument_list RPAREN" <<endl;
				$$ = new SymbolInfo("ID LPAREN argument_list RPAREN","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $4->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);

				/*
						Possible Function Call statement found.
						First,We have to check is this id exists or not..
						Then we have to check for its definition or declaration...
						After that we have to look for the parameters count
						Then check for type mismatch..
						Lets begin......
				*/

				SymbolInfo* tempSi = table->lookUp($1->name);

				if(tempSi == NULL){
					/*		This identifier doesn't exist		*/
					errorout << "Line# " << line_count << ": Undeclared function \'" << $1->name << "\'" <<endl;
					errorCount++;
					$$->varType = "NULL";					//This is for typecasting and error checking for later
				}
				else{
					/*		Identifier found		*/
					if(!(tempSi->isFunction)){
						/*
								It's not a function		
						*/
						errorout << "Line# " << line_count << ": \'"<<$1->name << "\' is not a function" <<endl;
						errorCount++;
						$$->varType = "NULL";					//This is for typecasting and error checking for later
					}
					else{
						/*
								It's a function		
								Check if it's defined or not
						*/
						if(!(tempSi->isFunctionDefined)){
							/*	 Function Definition doesn't exist	*/
							errorout << "Line# " << line_count << ": Undefined function \'" << $1->name << "\'" <<endl;
							errorCount++;
							$$->varType = "NULL";					//This is for typecasting and error checking for later
						}
						else{
							/*
									Ok!Function is defined.
									Now check for its parameters count
							*/
							if($3->argList.size() < tempSi->paramList.size()){
									/*
										Too few arguments
									*/
								errorout << "Line# "<<line_count << ": Too few arguments to function \'" << $1->name << "\'" <<endl;
								errorCount++;
								$$->varType = "NULL";					//This is for typecasting and error checking for later
							}
							else if(($3->argList.size() > tempSi->paramList.size())){
									/*
										Too many arguments
									*/
								errorout << "Line# " << line_count << ": Too many arguments to function \'" << $1->name << "\'" << endl;
								errorCount++;
								$$->varType = "NULL";					//This is for typecasting and error checking for later
							}
							else{
								/*
										Now check for parameter mismatch
								*/
								for(int i=0; i<tempSi->paramList.size() ; i++){
									if($3->argList[i] == "VOID"){
										/*		void error	*/
										errorout << "Line# " << line_count << ": Type mismatch for argument "<< i+1 <<" of \'" << $1->name << "\'" <<endl;;
										errorCount++;
										$$->varType = "NULL";					//This is for typecasting and error checking for later
									}
									else if($3->argList[i] == "NULL" || $3->argList[i] == "" || tempSi->paramList[i]->varType == "" || tempSi->paramList[i]->varType == "NULL"){
										/* 			Skip..This was handled before		*/
										$$->varType = "NULL";					//This is for typecasting and error checking for later
									}
									else if(tempSi->paramList[i]->varType == "INT" && ($3->argList[i] == "FLOAT" || $3->argList[i] == "FLOAT_ARRAY" )){
										/*			Type mismatch		*/
										errorout << "Line# " << line_count << ": Type mismatch for argument "<< i+1 <<" of \'" << $1->name << "\'" <<endl;
										errorCount++;
										$$->varType = "NULL";					//This is for typecasting and error checking for later
									}
									else if(tempSi->paramList[i]->varType == "FLOAT" && ($3->argList[i] == "INT" || $3->argList[i] == "INT_ARRAY" )){
										/*			Type mismatch		*/
										errorout << "Line# " << line_count << ": Type mismatch for argument "<< i+1 <<" of \'" << $1->name << "\'" <<endl;
										errorCount++;
										$$->varType = "NULL";					//This is for typecasting and error checking for later
									}
									else{
										/*
												At LAst!
												Everything Looks healthy..
										*/
										$$->varType = tempSi->varType;
									}
									
								}
							}
						}
					}
				}
				//cout << $$->startLine << "factor : ID lapre " << $$->varType <<endl;

	}
	| LPAREN expression RPAREN
	{
				logout << "factor : LPAREN expression RPAREN" <<endl;
				$$ = new SymbolInfo("LPAREN expression RPAREN","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);

				$$->varType = $2->varType;					//This is for typecasting and error checking for later
	}
	| CONST_INT 
	{
				logout << "factor : CONST_INT" <<endl;
				$$ = new SymbolInfo("CONST_INT","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);
				
				$$->zeroFlag = $1->zeroFlag;			//To handle zero flag
				$$->varType = "INT";					//This is for typecasting and error checking for later


				/*		ICG portion starts		*/

				// temp1out << "\t\t" << ";Line no# " << line_count << ": ***		pushing const int to stack		*** " << endl;
				// temp1out << "\t" << "MOV AX, " << stoi($1->name) << endl;
				// temp1out << "\t" << "PUSH AX" << endl;

				/*		ICG portion ends		*/
	}
	| CONST_FLOAT
	{
				logout << "factor : CONST_FLOAT" <<endl;
				$$ = new SymbolInfo("CONST_FLOAT","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->varType = "FLOAT";					//This is for typecasting and error checking for later
	}
	| ERROR_FLOAT
	{			
				/*		
						Extra rule added to detect ill formatted numbers and too many decimal point errors
				*/
				logout << "factor : ERROR_FLOAT" <<endl;
				$$ = new SymbolInfo("ERROR_FLOAT","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				//Because it's an error and this was handled in the lex file
				$$->varType = "NULL";					//This is for typecasting and error checking for later
	}
	| variable INCOP 
	{
				logout << "factor : variable INCOP" <<endl;
				$$ = new SymbolInfo("variable INCOP","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
	}
	| variable DECOP
	{
				logout << "factor : variable DECOP" <<endl;
				$$ = new SymbolInfo("variable DECOP","factor");
				$$->startLine = $1->startLine;		
				$$->endLine = $2->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);

				$$->varType = $1->varType;					//This is for typecasting and error checking for later
	}
	;
	
argument_list : arguments
			{
				logout << "argument_list : arguments" <<endl;
				$$ = new SymbolInfo("arguments","argument_list");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				//Pass the arguments saved in vector
				$$->argList = $1->argList;
				$$->varType = $1->varType;					//This is for typecasting and error checking for later

			}
			|
			{
				logout << "argument_list : " <<endl;
				$$ = new SymbolInfo("","argument_list");
				$$->startLine = line_count;		
				$$->endLine = line_count;
			}
			;
	
arguments : arguments COMMA logic_expression
			{
				logout << "arguments : arguments COMMA logic_expression" <<endl;
				$$ = new SymbolInfo("arguments COMMA logic_expression","arguments");
				$$->startLine = $1->startLine;		
				$$->endLine = $3->endLine;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);

				//Pass the arguments saved in vector
				$$->argList = $1->argList;
				$$->argList.push_back($3->varType);		//Update
			}
	      | logic_expression
		  {
				logout << "arguments : logic_expression" <<endl;
				$$ = new SymbolInfo("logic_expression","arguments");
				$$->startLine = $1->startLine;		
				$$->endLine = $1->endLine;
				$$->childList.push_back($1);

				$$->argList.push_back($1->varType);		//Update
				$$->varType = $1->varType;				//This is for typecasting and error checking for later
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{
	FILE *fp;
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		fclose(fp);
		exit(1);
	}
	
	table->enterScope();
	yyin=fp;
	yyparse();
	logout << "Total Lines: "<<line_count<<endl;
	logout << "Total Errors: "<<errorCount<<endl;
	fclose(fp);
	

	table2->enterScope();
	start(startNode);
	
	
	return 0;
}

