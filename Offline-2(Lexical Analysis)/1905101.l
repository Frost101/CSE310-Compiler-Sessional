%option noyywrap

%x singleLineCommentSt
%x multiLineCommentsSt
%x charLiteralSt
%x stringSt

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<fstream>
#include "1905101.h"

using namespace std;

int line_count = 1;
int numBuckets = 10;
int errorCount = 0;
string comments = "";
string str = "";
string plainStr = "";
bool multiLineStringFlag = false;
int newLineCount = 0;

ofstream logout;
ofstream tokenout;

SymbolTable st(numBuckets);


string toUpperCase(string s){
	for(int i=0; i<s.size(); i++){
		s[i] = toupper(s[i]);
	}
	return s;
}

char processConstChar(string s){
	char tmp;
	if(s.size()==3){
		tmp = s[1];
		return tmp;
	}
	else{
		if(s[1]=='\\'){
			if(s[2]=='n'){
				tmp = '\n';
			}
			else if(s[2]=='t'){
				tmp = '\t';
			}
			else if(s[2]=='\\'){
				tmp = '\\';
			}
			else if(s[2]=='\''){
				tmp = '\'';
			}
			else if(s[2]=='a'){
				tmp = '\a';
			}
			else if(s[2]=='f'){
				tmp = '\f';
			}
			else if(s[2]=='r'){
				tmp = '\r';
			}
			else if(s[2]=='b'){
				tmp = '\b';
			}
			else if(s[2]=='v'){
				tmp = '\v';
			}
			else if(s[2]=='0'){
				tmp = '\0';
			}
			else if(s[2]=='\"'){
				tmp = '\"';
			}
			else{
				tmp = s[2];
			}

		}
		return tmp;
	}
}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE [\r]?\n

%%

{NEWLINE} {line_count++;}

{WHITESPACE} {/*	ignore the whitespace	*/ }

"if"		|

"else"		|

"for"		|

"while"		|

"do"		|

"break"		|

"int"		|

"char"		|

"float"		|

"double"	|

"void"		|

"return"	|

"switch"	|

"case"		|

"default"	|

"continue"	{
			string tmpStr = toUpperCase(yytext);
			tokenout<<"<"<<tmpStr<<", "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <"<<tmpStr<<"> Lexeme "<<yytext<<" found"<<endl;
			}

{DIGIT}+ 	{
				/*		Integer Literals		*/
				tokenout<<"<CONST_INT, "<<yytext<<">"<<endl;
				logout<<"Line# "<<line_count<<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;
				//insert in symbol table and print symbol table content(only non empty buckets)
				// SymbolInfo* si = new SymbolInfo(string(yytext),"CONST_INT");
				// if(st.insert(*si)){
				// 	st.print(logout);
				// }
			}

(({DIGIT}+(\.{DIGIT}*)?)|({DIGIT}*(\.{DIGIT}+)?))([Ee][-+]?{DIGIT}+)?	{
				/*		Floating Point Literals		*/
				tokenout<<"<CONST_FLOAT, "<<yytext<<">"<<endl;
				logout<<"Line# "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found"<<endl;
				// SymbolInfo* si = new SymbolInfo(string(yytext),"CONST_FLOAT");
				// if(st.insert(*si)){
				// 	st.print(logout);
				// }
			}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*	{
				/*		Too Many Decimal Points		*/
				logout<<"Error at line# "<<line_count<<": TOO_MANY_DECIMAL_POINTS "<< yytext <<endl;
				errorCount++;
			}


({DIGIT}*(\.{DIGIT}*)?[Ee][+-]?{DIGIT}*[0-9\.Ee+-]*(\.)*)|({DIGIT}+\.)	{
				/*		Ill formatted Number		*/
				logout<<"Error at line# "<<line_count<<": ILLFORMED_NUMBER "<< yytext <<endl;
				errorCount++;
			}

"+"		|
"-"		{
			/*		ADDOP		*/
			tokenout<<"<ADDOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <ADDOP> Lexeme "<<yytext<<" found"<<endl;
		}

"*"		|
"/"		|
"%"		{
			/*		MULOP		*/
			tokenout<<"<MULOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <MULOP> Lexeme "<<yytext<<" found"<<endl;
		}

"++"	|
"--"	{
			/*		INCOP		*/
			tokenout<<"<INCOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <INCOP> Lexeme "<<yytext<<" found"<<endl;
		}

"<"		|
"<="	|
">"		|
">="	|
"=="	|
"!="	{
			/*		RELOP		*/
			tokenout<<"<RELOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <RELOP> Lexeme "<<yytext<<" found"<<endl;
		}

"="		{
			/*		ASSIGNOP		*/
			tokenout<<"<ASSIGNOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found"<<endl;
		}				

"&&"	|
"||"	{
			/*		LOGICOP		*/
			tokenout<<"<LOGICOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <LOGICOP> Lexeme "<<yytext<<" found"<<endl;
		}

"&"		|
"|"		|
"^"		|
"<<"	|
">>"	{
			/*		BITOP		*/
			tokenout<<"<BITOP, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <BITOP> Lexeme "<<yytext<<" found"<<endl;
		}

"!"		{
			/*		NOT		*/
			tokenout<<"<NOT, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <NOT> Lexeme "<<yytext<<" found"<<endl;
		}

"("		{
			/*		LPAREN		*/
			tokenout<<"<LPAREN, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <LPAREN> Lexeme "<<yytext<<" found"<<endl;
		}

")"		{
			/*		RPAREN		*/
			tokenout<<"<RPAREN, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <RPAREN> Lexeme "<<yytext<<" found"<<endl;
		}

"{"		{
			/*		LCURL		*/
			tokenout<<"<LCURL, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <LCURL> Lexeme "<<yytext<<" found"<<endl;
			st.enterScope();
		}

"}"		{
			/*		RCURL		*/
			tokenout<<"<RCURL, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <RCURL> Lexeme "<<yytext<<" found"<<endl;
			st.exitScope();
		}

"["		{
			/*		LSQUARE		*/
			tokenout<<"<LSQUARE, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <LSQUARE> Lexeme "<<yytext<<" found"<<endl;
		}		

"]"		{
			/*		RSQUARE		*/
			tokenout<<"<RSQUARE, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <RSQUARE> Lexeme "<<yytext<<" found"<<endl;
		}

","		{
			/*		COMMA		*/
			tokenout<<"<COMMA, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <COMMA> Lexeme "<<yytext<<" found"<<endl;
		}

";"		{
			/*		SEMICOLON		*/
			tokenout<<"<SEMICOLON, "<<yytext<<">"<<endl;
			logout<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
		}		

[_A-Za-z][_0-9A-Za-z]*	{
				/*		Identifiers		*/
				tokenout<<"<ID, "<<yytext<<">"<<endl;
				logout<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
				SymbolInfo* si = new SymbolInfo(string(yytext),"ID");
				if(st.insert(*si)){
					st.print(logout);
				}
				else{
					logout<<"\t"<<yytext<<" already exisits in the current ScopeTable"<<endl;
				}
			}

(({DIGIT}+(\.{DIGIT}*)?)|({DIGIT}*(\.{DIGIT}+)?))([Ee][-+]?{DIGIT}+)?[_a-zA-Z][_0-9a-zA-Z]*	{
					/*		Invalid suffix or prefix		*/
					errorCount++;
					logout<<"Error at line# "<<line_count<<": INVALID_ID_SUFFIX_NUM_PREFIX "<<yytext<<endl; 

			}

\/\/		{
				/*		Single Line Comment		*/
				comments = "";					//Initialize Comment
				comments += "//";
				BEGIN singleLineCommentSt;
			}

<singleLineCommentSt><<EOF>>	{
				/*			IF End of file Found at the end of comment,so end it  */
				logout<<"Line# "<<line_count<<": Token <SINGLE LINE COMMENT> Lexeme "<<comments<<" found"<<endl; 
				comments = ""; 						//Initializing comments for later
				line_count += newLineCount; 	//update line count
				newLineCount = 0;				//reset
				BEGIN INITIAL;						//Go Back To Initial State
			}


<singleLineCommentSt>\\{NEWLINE}	{
				/*		MultiLine Commment Started with a double slash And new Line appeared		*/
				newLineCount++;
				comments += "\\\n";							// \ mark and a new line has been added
			}

<singleLineCommentSt>{NEWLINE}	{
				/*		if new line is found in single line comments,end it		*/
				logout<<"Line# "<<line_count<<": Token <SINGLE LINE COMMENT> Lexeme "<<comments<<" found"<<endl; 
				newLineCount++;
				line_count += newLineCount;			//update real line counts for later
				comments = "";								//Initialize comments
				newLineCount = 0;						//reset
				BEGIN INITIAL;								//Go Back to INITIAL state
			}

<singleLineCommentSt>.	{
				/*		Add other letters to the comment		*/
				comments += yytext[0];
			}


\/\*		{
				/*		Multi Line Comments Detected	*/
				newLineCount = 0;       //Reset
				comments = "";				//Initialize
				comments += "/*";       	//Comment start
				BEGIN multiLineCommentsSt;
			}

<multiLineCommentsSt><<EOF>>	{
				/*		Unfinished Comment		*/
				logout<<"Error at line# "<<line_count+newLineCount<<": UNFINISHED_COMMENT "<<comments<<endl;
				errorCount++;
				line_count += newLineCount;		//update line counts
				/* reset all */
				comments = "";
				newLineCount = 0;
				BEGIN INITIAL;
			}

<multiLineCommentsSt>{NEWLINE}	{
				/* 		Go to next Line		*/
				newLineCount++;				//Update new Line Count
				comments += "\n";
			}	

<multiLineCommentsSt>\*\/	{
				/*		End of this comment		*/
				comments += "*/";
				logout<<"Line# "<<line_count<<": Token <MULTI LINE COMMENT> Lexeme "<<comments<<" found"<<endl;
				line_count += newLineCount;			//Update Line Count
				newLineCount = 0;						//Reset
				comments = "";								//Initialize
				BEGIN INITIAL;								//Go to Initial State
			}		

<multiLineCommentsSt>.		{
				/*		Add any other characters		*/
				comments += yytext[0];
			}

\'\'			{
				/*		Empty Char Error		*/
				errorCount++;
				logout<<"Error at line# "<<line_count<<": EMPTY_CONST_CHAR "<<yytext<<endl;
			}

\'([ -~]{-}[\"\'\\])\'|\'(\\[\\ntfarbv0\"\'])\'		{
				/*		CONST_CHAR FOUND		*/
				char tmp = processConstChar(yytext);
				logout<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<tmp<<" found"<<endl;
				tokenout<<"<CONST_CHAR, "<<tmp<<">"<<endl;
			}

\'(([ -~]{-}[\"\'\\])|(\\[\\ntfarbv0\"\']))*\'		{
				/*		MultiChar Error		*/
				errorCount++;
				logout<<"Error at line# "<<line_count<<": MULTICHAR_CONST_CHAR "<<yytext<<endl;
			}

\'(([ -~]{-}[\"\'\\])|(\\[\\ntfarbv0\"\'])){0,1}|\'[\\]\'	{
				/*		Unfinished Const Char		*/
				errorCount++;
				logout<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR "<<yytext<<endl;
			}



\"			{
				/*		Start of a String Found		*/
				str = "";						//Initialize
				plainStr ="";					//Initialize
				plainStr = "\"";
				multiLineStringFlag = false;	//Initialize
				newLineCount = 0;			//Reset
				BEGIN stringSt;					//Go to stringSt State
			}

<stringSt>\\\"		{
				str += "\"";
				plainStr += "\\\"";
			}
<stringSt>\\\'		{
				str += "\'";
				plainStr += "\\\'";
			}
<stringSt>\\n		{
				str += "\n";
				plainStr += "\\n";
			}			
<stringSt>\\t		{
				str += "\t";
				plainStr += "\\t";
			}
<stringSt>\\\\		{
				str += "\\";
				plainStr += "\\\\";
			}
<stringSt>\\a		{
				str += "\a";
				plainStr += "\\a";
			}
<stringSt>\\f		{
				str += "\f";
				plainStr += "\\f";
			}
<stringSt>\\r		{
				str += "\r";
				plainStr += "\\r";
			}
<stringSt>\\b		{
				str += "\b";
				plainStr += "\\b";
			}
<stringSt>\\v		{
				str += "\v";
				plainStr += "\\v";
			}			
<stringSt>\\0		{
				str += "\0";
				plainStr += "\\0";
			}

<stringSt><<EOF>>	{
				/*		Unexpected End Of File.Report an error		*/
				logout<<"Error at line# "<<line_count+newLineCount<<": UNFINISHED_STRING "<<plainStr<<endl;
				errorCount++;
				line_count += newLineCount;		//Update Line count
				str = "";								//Initialize
				plainStr = "";							//Initialize
				multiLineStringFlag = false;			//Reset
				newLineCount = 0;					//Reset
				BEGIN INITIAL;							//Go Back to initial state
			}

<stringSt>{NEWLINE}		{
				/*		Unexpected Newline,Report an error		*/
				logout<<"Error at line# "<<line_count+newLineCount<<": UNFINISHED_STRING "<<plainStr<<endl;
				newLineCount++;					//Update Line Count cuz you found a new line
				errorCount++;
				line_count += newLineCount;
				str = "";								//Initialize
				plainStr = "";							//Initialize
				multiLineStringFlag = false;			//Reset
				newLineCount = 0;					//Reset
				BEGIN INITIAL;							//Go Back to initial state
			}

<stringSt>\\{NEWLINE}		{
				/*		Multiline String		*/
				newLineCount++;
				//str+= "\t";
				plainStr += "\\";
				plainStr += "\n";
				multiLineStringFlag = true;
			}

<stringSt>\"		{
				/*		End Of String		*/
				plainStr += "\"";
				if(!multiLineStringFlag){
					logout<<"Line# "<<line_count<<": Token <SINGLE LINE STRING> Lexeme "<<plainStr<<" found"<<endl;
					tokenout<<"<SINGLE LINE STRING, "<<str<<">"<<endl;
				}
				else{
					logout<<"Line# "<<line_count<<": Token <MULTI LINE STRING> Lexeme "<<plainStr<<" found"<<endl;
					tokenout<<"<MULTI LINE STRING, "<<str<<">"<<endl;
				}
				str = "";
				plainStr = "";
				line_count += newLineCount;
				newLineCount = 0;
				multiLineStringFlag = false;
				BEGIN INITIAL;
				
			}

<stringSt>.		{
				/*		Anything Else	*/
				str += yytext[0];
				plainStr += yytext[0];
			}

.			{	
				/* 		Unrecognized Character Found		*/
				errorCount++;
				logout<<"Error at line# "<<line_count<<": UNRECOGNIZED_CHAR "<<yytext[0]<<endl;	 
			}

%%

int main(int argc, char** argv) {
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("log.txt", ios::out);
	tokenout.open("token.txt", ios::out);

	yyin = fin;
	st.enterScope();
	yylex();
	st.print(logout);
	logout<<"Total lines: "<<line_count<<endl;
	logout<<"Total errors: "<<errorCount<<endl;
	fclose(yyin);
	tokenout.close();
	logout.close();
	return 0;
}
