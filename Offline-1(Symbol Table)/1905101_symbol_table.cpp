/*
    1905101
    MD Sadik Hossain Shanto
    Offline:01: Inplementation of Symbol Table
*/

#include<iostream>
#include<fstream>
#include<cstdlib>
#include<string>
using namespace std;


class SymbolInfo{
    private:
        string name;
        string type;
        SymbolInfo* next;   //For Chaining Mechanism in The Hash Table

    public:
        SymbolInfo(){
            /*  Default Constructor */
            this->name = "";
            this->type = "";
            this->next = NULL;
        }

        SymbolInfo(string name,string type){
            /*  Constructor For Setting Name And Type   */
            this->name = name;
            this->type = type;
            this->next = NULL;
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
            //delete next;
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
                cout << '\t' << "'" << symbolName << "'" << " found in ScopeTable# "<< this->id << " at position "<< index+1 << ", " << position << endl;
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
                cout << '\t' << "'" << symbolInfo.getName() << "'" << " already exists in the current ScopeTable" << endl;
                return false; 
            }
            else{
                /*      If Not Found Then insertion process begins       */
                tmp = bucketArray[index];
                int position = 1;
                if(tmp == NULL){
                    /*      If The Bucket is Empty      */
                    bucketArray[index] = &symbolInfo;
                    cout << '\t' << "Inserted in ScopeTable# " << this->id << " at position " << index+1 << ", 1" << endl;
                    return true;
                }

                position++;
                while(tmp->getNext() != NULL){
                    tmp = tmp->getNext();
                    position++;
                }
                tmp->setNext(&symbolInfo);
                cout << '\t' << "Inserted in ScopeTable# " << this->id << " at position " << index+1 << ", " << position << endl;
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
                cout << '\t' << "Not found in the current ScopeTable" << endl;
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
            //delete tmp;
            
            cout << '\t' << "Deleted " << "'" << symbolName << "'" << " from ScopeTable# " << this->id << " at position " << index+1 << ", " << position << endl;
            return true;
        }



        void print(){
            cout << '\t' << "ScopeTable# " << this->id << endl;
            for(int i = 0; i < numBuckets; i++){
                cout << '\t' << i+1 << "--> ";
                SymbolInfo* tmp = bucketArray[i];
                while(tmp != NULL){
                    cout << "<" << tmp->getName() << "," << tmp->getType() << "> ";
                    tmp = tmp->getNext(); 
                }
                cout << endl;
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
    
    public:
        SymbolTable(){
            /*      Default Constructor     */
            current = NULL;
        }

        void enterScope(int id, int numBuckets){
            ScopeTable* scopeTable = new ScopeTable(id, numBuckets, this->current);       //Create a new scope table and make the current scope its parent
            current = scopeTable;                                       //Make the current pointer point to the new scope table
            cout << '\t' << "ScopeTable# " << id << " created" <<endl; 
        }

        void exitScope(){
            if(current == NULL){
                /*      If The Symbole Table Is Empty       */
                return;
            }
            if(current->getParentScope() == NULL){
                /*      Cannot exit the root scope table        */
                cout << '\t' << "ScopeTable# " << current->getId() << " cannot be removed" <<endl;
                return;
            }
            /*      Current Pointer Points To Its Parent Scope      */
            cout << '\t' << "ScopeTable# " << current->getId() << " removed" << endl;
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
            cout << '\t' << "'" << symbolName << "'" << " not found in any of the ScopeTables" << endl;
            return NULL;
        }

        void printCurrentScopeTable(){
            if(current == NULL){
                /*      If The Scope Table Is Empty     */
                return;
            }
            current->print();
        }

        void printAllScopeTable(){
            if(current == NULL){
                /*      If The Scope Table Is Empty     */
                return;
            }
            ScopeTable* tmp = current;
            while(tmp != NULL){
                tmp->print();
                tmp = tmp->getParentScope();
            }
        }

        ~SymbolTable(){
             /*      Destructor Function     */
             while(current != NULL){
                cout << '\t' << "ScopeTable# " << current->getId() << " removed";
                if(current->getParentScope() == NULL){
                    break;
                }
                cout << endl;
                current = current->getParentScope();
            }
        }


};



int main()
{
    freopen("input.txt", "r", stdin);
	freopen("output.txt", "w", stdout);



    
    string n;
    int cnt=10;
    getline(cin,n);
    int numBuckets = stoi(n);       //number of buckets in chained hash
    int currentId = 1;              //current scope id
    int cmdNo = 1;                  //Command No

    SymbolTable* symbolTable = new SymbolTable();
    symbolTable->enterScope(currentId, numBuckets);


    string str;

    
    while(true){
        getline(cin,str);

        string input[3];
        input[0] = "$";
        input[1] = "$";
        input[2] = "$";

        string word = "";
        int i = 0;
        int len = str.length();
        int wordCount = 0;
        bool falsecmd = false; 
        for(int j=0; j<len; j++){
            if(str[j] == ' ' || j == len-1){
                wordCount++;
                if(wordCount > 3){
                    break;
                }
                if(j == len-1 && str[j] != ' ')word = word + str[j];
                input[i] = word;
                word = "";
                i++;
            }
            else{
                word = word+str[j];
            }
        }

        if(wordCount > 3){
            cout << "Cmd " << cmdNo <<": ";
            cout << str << endl;
            cout << '\t' << "Number of parameters mismatch for the command " << input[0] << endl;
            cmdNo++;
            continue;
        }

        cout << "Cmd " << cmdNo <<":";
        if(input[0] != "$"){
            cout << " " << input[0];
        }
        if(input[1] != "$"){
            cout << " " << input[1];
        }
        if(input[2] != "$"){
            cout << " " << input[2];
        }
        cout << endl;
        cmdNo++;

        

        if(input[0] == "Q"){
            delete symbolTable;
            break;
        }

        else if(input[0] == "I"){
            if(input[1] == "$" || input[2] == "$"){
                cout << '\t' << "Number of parameters mismatch for the command I" << endl;
            }
            else{
                SymbolInfo* symbolInfo = new SymbolInfo(input[1], input[2]);
                symbolTable->insert(*symbolInfo);
            }
        }

        else if(input[0] == "L"){
            if(input[1] == "$" || input[2] != "$"){
                cout << '\t' << "Number of parameters mismatch for the command L" << endl;
            }
            else{
                symbolTable->lookUp(input[1]);
            }
        }

        else if(input[0] == "P"){
            if(input[1] == "$" || input[2] != "$"){
                cout << '\t' << "Number of parameters mismatch for the command P" << endl;
            }
            else{
                if(input[1] == "C"){
                    symbolTable->printCurrentScopeTable();
                }
                else if(input[1] == "A"){
                    symbolTable->printAllScopeTable();
                }
                else{
                    cout << '\t' << "Number of parameters mismatch for the command P" << endl;
                }
            }
        }

        else if(input[0] == "D"){
            if(input[1] == "$" || input[2] != "$"){
                cout << '\t' << "Number of parameters mismatch for the  command D" << endl;
            }
            else{
                symbolTable->remove(input[1]);
            }
        }

        else if(input[0] == "S"){
            if(input[1] != "$" || input[2] != "$"){
                cout << '\t' << "Number of parameters mismatch for the command S" << endl;
            }
            else{
                currentId++;
                symbolTable->enterScope(currentId, numBuckets);
            }
        }

        else if(input[0] == "E"){
            if(input[1] != "$" || input[2] != "$"){
                cout << '\t' << "Number of parameters mismatch for the command E" << endl;
            }
            else{
                symbolTable->exitScope();
            }
        }  
    }

}