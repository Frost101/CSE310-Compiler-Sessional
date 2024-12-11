/*
    1905101
    MD Sadik Hossain Shanto
    Offline:01: Inplementation of Symbol Table
*/

#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include<bits/stdc++.h>
using namespace std;


class SymbolInfo{
    public:
        string name;
        string type;
        SymbolInfo* next;   //For Chaining Mechanism in The Hash Table
        int startLine;      //For Printing Parse Tree
        int endLine;        //For Printing Parse Tree
        string varType;        //Return type and type Specifier
        vector<SymbolInfo*> childList;   //If it is a non-terminal symbol,then insert the children
        vector<SymbolInfo*> decList;        //int a,b,c
        vector<SymbolInfo*> paramList;     //Function input parameters
        vector<string> argList;            //argument type passed in function caalls
        bool isLeaf;
        bool isFunction;
        bool isFunctionDeclared;
        bool isFunctionDefined;
        bool zeroFlag;
        bool isGlobal;
        int offset;
        bool isArray;
        int arraySize;


    
        SymbolInfo(){
            /*  Default Constructor */
            this->name = "";
            this->type = "";
            this->next = NULL;

            startLine = 0;
            endLine = 0;
            varType = "";
            isLeaf = false;
            isFunctionDeclared = false;
            isFunction = false;
            isFunctionDefined = false;
            zeroFlag = false;
            isGlobal = false;
            offset = -1;
            isArray = false;
            arraySize = 0;
        }

        SymbolInfo(string name,string type){
            /*  Constructor For Setting Name And Type   */
            this->name = name;
            this->type = type;
            this->next = NULL;

            startLine = 0;
            endLine = 0;
            varType = "";
            isLeaf = false;
            isFunctionDeclared = false;
            isFunction = false;
            isFunctionDefined = false;
            zeroFlag = false;
            isGlobal = false;
            offset = -1;
            isArray = false;
            arraySize = 0;
        }

        void setName(string name){
            /*  Setter Function For Symbole Name    */
            this->name = name;
        }

        string getName(){
            /*  Getter Function For Symbole Name    */
            return this->name;
        }

        void setType(string type){
            /*  Setter Function For Symbole Type    */
            this->type = type;
        }

        string getType(){
            /*  Getter Function For Symbole Type*/
            return this->type;
        }

        void setNext(SymbolInfo* next){
            /*  Setter Function For Next Pointer    */
            this->next = next;
        }

        SymbolInfo* getNext(){
            /*  Getter Function For Next Pointer    */
            return this->next;
        }

        ~SymbolInfo(){
            /*  Destructor  */
            delete next;
        }

};



class ScopeTable{
    private:
        int id;                     //Unique Id for Each Scope Table
        int numBuckets;             //Number of Buckets in The Hash Table
        SymbolInfo** bucketArray;   //An Array for The Pointers of SymbolInfo Type For Chained Hash
        ScopeTable* parentScope;    //Pointer to its parent Scope Table

        unsigned long long int sdbmHash(string symbolName){
            /*  Hash Function For The Chained Hash Table    */
            unsigned long long int hash = 0;
            unsigned long long int i = 0;
            unsigned long long int len = symbolName.length();
            for(i = 0; i < len; i++){
                hash = (symbolName[i]) + (hash << 6) + (hash << 16) - hash;
            }
            return hash;
        }

    public:
        ScopeTable(){
            /*      Default Constructor     */
            bucketArray = NULL;
            parentScope = NULL;
        }

        ScopeTable(int id, int numBuckets, ScopeTable* parentScope){
            this->id = id;
            this->numBuckets = numBuckets;
            this->parentScope = parentScope;

            /*      Initialize Bucket Array     */
            bucketArray = new SymbolInfo*[numBuckets];
            for(int i = 0; i < numBuckets; i++){
                bucketArray[i] = NULL;
            }
        }


        SymbolInfo* lookUp(string symbolName){
            int index = int(sdbmHash(symbolName) % numBuckets);
            int position = 1;
            SymbolInfo* tmp = bucketArray[index];         //Pointer to the hashed index
            bool flag = false;                           //Flag True If Found

            while(tmp != NULL){
                if(tmp->getName() == symbolName){
                    flag = true;
                    break;
                }
                position++;
                tmp = tmp->getNext();                   //If Not Found Then Look in the next element of the chain
            }

            if(flag){
                /*      If Found Then return a pointer      */
                //cout << '\t' << "'" << symbolName << "'" << " found in ScopeTable# "<< this->id << " at position "<< index+1 << ", " << position << endl;
                return tmp;
            }
            else{
                /*      If Not Found Then Return Null       */
                return NULL;
            }
        }


        bool insert(SymbolInfo& symbolInfo){
            /*      First Look up if this symbol is already inserted or not     */
            int index = int(sdbmHash(symbolInfo.getName()) % numBuckets);
            SymbolInfo* tmp = bucketArray[index];        //Pointer to the hashed index
            bool flag = false;                           //Flag True If Found
            while(tmp != NULL){
                if(tmp->getName() == symbolInfo.getName()){
                    flag = true;
                    break;
                }
                tmp = tmp->getNext();                   //If Not Found Then Look in the next element of the chain
            }
            if(flag){
                /*      If Found Then it can't be inserted again     */
                //cout << '\t' << "'" << symbolInfo.getName() << "'" << " already exists in the current ScopeTable" << endl;
                return false;
            }
            else{
                /*      If Not Found Then insertion process begins       */
                tmp = bucketArray[index];
                int position = 1;
                if(tmp == NULL){
                    /*      If The Bucket is Empty      */
                    bucketArray[index] = &symbolInfo;
                    //cout << '\t' << "Inserted in ScopeTable# " << this->id << " at position " << index+1 << ", 1" << endl;
                    return true;
                }

                position++;
                while(tmp->getNext() != NULL){
                    tmp = tmp->getNext();
                    position++;
                }
                tmp->setNext(&symbolInfo);
                //cout << '\t' << "Inserted in ScopeTable# " << this->id << " at position " << index+1 << ", " << position << endl;
                return true;
            }
        }


        bool remove(string symbolName){
            /*      First Look up if this symbol exists or not     */
            int index = int(sdbmHash(symbolName) % numBuckets);
            int position = 1;
            SymbolInfo* tmp = bucketArray[index];        //Pointer to the hashed index
            bool flag = false;                           //Flag True If Found
            while(tmp != NULL){
                if(tmp->getName() == symbolName){
                    flag = true;
                    break;
                }
                position++;
                tmp = tmp->getNext();                   //If Not Found Then Look in the next element of the chain
            }
            if(flag == false){
                /*      If Not Found Then it can't be deleted     */
                //cout << '\t' << "Not found in the current ScopeTable" << endl;
                return false;
            }

            /*      If Found Then Delete It     */
            tmp = bucketArray[index];                   //Pointer to the hashed index
            SymbolInfo* parent = tmp;
            while(tmp->getName() != symbolName){
                parent = tmp;
                tmp = tmp->getNext();
            }

            if(tmp == parent){
                /*      If it is the only element in the bucket then        */
                bucketArray[index] = tmp->getNext();
            }
            else{
                parent->setNext(tmp->getNext());
            }
            delete tmp;

            //cout << '\t' << "Deleted " << "'" << symbolName << "'" << " from ScopeTable# " << this->id << " at position " << index+1 << ", " << position << endl;
            return true;
        }



        void print(ofstream &out){
            out << '\t' << "ScopeTable# " << this->id << endl;
            for(int i = 0; i < numBuckets; i++){
                SymbolInfo* tmp = bucketArray[i];
                SymbolInfo* tmp2 = tmp;
                if(tmp2 != NULL)  out << '\t' << i+1 << "--> ";
                while(tmp != NULL){
                    out << "<" << tmp->getName() << "," << tmp->getType() << "> ";
                    tmp = tmp->getNext();
                }
                if(tmp2 != NULL) out << endl;
            }
        }


        void setParentScope(ScopeTable* parentScope){
            this->parentScope = parentScope;
        }

        ScopeTable* getParentScope(){
            return this->parentScope;
        }

        void setId(int id){
            this->id = id;
        }

        int getId(){
            return this->id;
        }


        ~ScopeTable(){
            /*      Destructor:Free The Bucket Array        */
            delete[] bucketArray;
        }
};



class SymbolTable{
    private:
        ScopeTable* current;        //Pointer to the current scope table
        int numBuckets;
        int id;

    public:
        SymbolTable(int numBuckets){
            /*     Constructor     */
            this->numBuckets = numBuckets;
            current = NULL;
            this->id = 0;
        }

        int currentScopeNo(){
            return id;
        }

        void enterScope(){
            this->id++;
            ScopeTable* scopeTable = new ScopeTable(id, numBuckets, this->current);       //Create a new scope table and make the current scope its parent
            current = scopeTable;                                       //Make the current pointer point to the new scope table
            //cout << '\t' << "ScopeTable# " << id << " created" <<endl;
        }

        void exitScope(){
            if(current == NULL){
                /*      If The Symbole Table Is Empty       */
                return;
            }
            if(current->getParentScope() == NULL){
                /*      Cannot exit the root scope table        */
                //cout << '\t' << "ScopeTable# " << current->getId() << " cannot be removed" <<endl;
                return;
            }
            /*      Current Pointer Points To Its Parent Scope      */
            //cout << '\t' << "ScopeTable# " << current->getId() << " removed" << endl;
            current = current->getParentScope();
        }

        bool insert(SymbolInfo& symbolInfo){
            if(current == NULL){
                /*      If the Symbol Table Is Empty       */
                return false;
            }
            return current->insert(symbolInfo);
        }

        bool remove(string symbolName){
            if(current == NULL){
                /*      If The Scope Table Is Empty     */
                return false;
            }
            return current->remove(symbolName);
        }

        SymbolInfo* lookUp(string symbolName){
            if(current == NULL){
                  /*      If The Scope Table Is Empty     */
                  return NULL;
            }
            ScopeTable* tmp = current;
            while(tmp != NULL){
                SymbolInfo* symbolInfo = tmp->lookUp(symbolName);
                if(symbolInfo != NULL) return symbolInfo;                   //Found The Symbol
                tmp = tmp->getParentScope();                                 //If Not Found Then Search In its Parent Scope
            }
            /*      If not found in any of the scopes       */
            //cout << '\t' << "'" << symbolName << "'" << " not found in any of the ScopeTables" << endl;
            return NULL;
        }

        void printCurrent(ofstream &out){
            if(current == NULL){
                /*      If The Scope Table Is Empty     */
                return;
            }
            current->print(out);
        }

        void print(ofstream &out){
            if(current == NULL){
                /*      If The Scope Table Is Empty     */
                return;
            }
            ScopeTable* tmp = current;
            while(tmp != NULL){
                tmp->print(out);
                tmp = tmp->getParentScope();
            }
        }

        ~SymbolTable(){
             /*      Destructor Function     */
             while(current != NULL){
                //cout << '\t' << "ScopeTable# " << current->getId() << " removed";
                if(current->getParentScope() == NULL){
                    break;
                }
                //cout << endl;
                current = current->getParentScope();
            }
        }


};

#endif

