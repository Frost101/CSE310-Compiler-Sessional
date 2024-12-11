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

int bucketSize = 11;
SymbolTable *table = new SymbolTable(bucketSize);


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


/*		To detect Functions 	*/
vector<SymbolInfo*> params;
bool isFunction = false;

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

		printParseTree($$,0);
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
		}
		| type_specifier ID LPAREN RPAREN {
					isFunction = true;								//Definition could be a valid function
					insert_function_to_global_scope($2,$1,false);	//first insert this function to the global scope\
																	function paramater list is absent,so 3rd parameter is false	
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
	

	/* fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a"); */
	
	
	return 0;
}

