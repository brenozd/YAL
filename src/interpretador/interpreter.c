#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include "nodes.h"
#include "../../obj/YAL.tab.h"

#define sizeof_Node (sizeof(nodeEnum) + sizeof(node*))

//Pointer to a chain-structure (symbol table)
node *id_table = NULL;
//Pointer to a chain-structure with all nodes allocated
node *node_list = NULL;

extern FILE *yycmd;
extern int n_line;

//Get a specific symbol from id_table
node *getSymbol(char const *name)
{
    node *_node = NULL;
    for (node *p = id_table; p; p = p->id.next)
        if (strcmp(p->id.name, name) == 0)
            _node = p;
    return _node;
}

//Check and list every variable in id_table
void checkSymbols()
{
    for (idNode *p = id_table; p; p = p->next)
    {
        printf("[%s, %d]\n", p->name, p->value);
    }
}

//Create a constant node to store value
node *constant(int value)
{
    node *_node = NULL;
    size_t nodeSize;
    nodeSize = sizeof_Node + sizeof(constNode);
    if ((_node = malloc(nodeSize)) == NULL)
        yyerror("Out of memory");
    _node->type = t_Constant;
    _node->cnt.value = value;
    _node->next = node_list;
    node_list = _node;

    fprintf(yycmd, "creating constant %d\n",  _node->cnt.value);
    return _node;
}

//Create a id node to store a variable type
node *id(char const *name)
{
    char *_name = strdup(name);
    node *_node = getSymbol(_name);
    if (_node == NULL)
    {
        
        size_t nodeSize;
        nodeSize = sizeof_Node + sizeof(idNode);
        if ((_node = malloc(nodeSize)) == NULL)
            yyerror("Out of memory");
        _node->type = t_Id;
        _node->id.name = _name;
        _node->id.value = 0;
        _node->id.next = id_table;
        id_table = _node;
        _node->next = node_list;
        node_list = _node;

        fprintf(yycmd, "creating variable %s\n",  _name);
    }
    else
    {
        printf("In line: %d, variable %s already exist\n",  name);
        exit(0);
    }
    return _node;
}

//Create a statement node
node *stmt(int opr, int num_operators, ...)
{
    va_list args;
    node *_node = NULL;
    size_t nodeSize;
    nodeSize = sizeof_Node + sizeof(stmtNode) + (num_operators - 1) * (sizeof(stmtNode *));
    if ((_node = malloc(nodeSize)) == NULL)
        yyerror("Out of memory");

    _node->type = t_Statement;
    _node->stmt.opr = opr;
    _node->stmt.num_operators = num_operators;
    _node->next = node_list;
    node_list = _node;
    va_start(args, num_operators);
    for (size_t i = 0; i < num_operators; i++)
    {
        _node->stmt.op[i] = va_arg(args, node *);
    }
    va_end(args);
    

    return _node;
}

//Free nodes and sub-nodes
void freeNode(node *_node)
{
    if(_node->next != NULL)
        freeNode(_node->next);
        free(_node);
}

//Execute node based on node type and flag
int execNode(node *_node)
{

    if (!_node)
        return 0;

    switch (_node->type)
    {

    case t_Constant:
        return _node->cnt.value;
        break;

    case t_Id:
    {
        node *n = getSymbol(_node->id.name);
        return n != NULL ? n->id.value : yyerror("Variable does not exist");
        break;
    }

    case t_Statement:
        switch (_node->stmt.opr)
        {
/*---------------------------------------------------------------------------------
                                Assign and compose
---------------------------------------------------------------------------------*/
        case T_ASSGN:
        {
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                int v = execNode(_node->stmt.op[1]);
                fprintf(yycmd, "assigned value %d to %s\n",  v, n->id.name);
                return n->id.value = v;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_SUME:
        {
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                int v = execNode(_node->stmt.op[1]);
                fprintf(yycmd, "summed value %d to %s\n", v, n->id.name);
                return n->id.value += v;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_SUBE:
        {
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                int v = execNode(_node->stmt.op[1]);
                fprintf(yycmd, "subtracted value %d from %s\n",  v, n->id.name);
                return n->id.value -= v;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_MULTE:
        {
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                int v = execNode(_node->stmt.op[1]);
                fprintf(yycmd, "multiplied value from %s by %d\n", n->id.name, v);
                return n->id.value *= v;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_DIVE:
        {
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                int v = execNode(_node->stmt.op[1]);
                fprintf(yycmd, "divided value from %s by %d\n", n->id.name, v);
                return n->id.value /= v;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

/*---------------------------------------------------------------------------------
                            Loops, conditional and EOS
---------------------------------------------------------------------------------*/
        case T_EOS:
            execNode(_node->stmt.op[0]);
            return execNode(_node->stmt.op[1]);

        case T_WHILE:
            while (execNode(_node->stmt.op[0]) != 0)
                execNode(_node->stmt.op[1]);
            return 0;

        case T_IF:
        {
            fprintf(yycmd, "if statement with condition ");
            if (execNode(_node->stmt.op[0]))
                execNode(_node->stmt.op[1]);
            else if (_node->stmt.num_operators > 2)
                execNode(_node->stmt.op[2]);
            return 0;
        }
            

/*---------------------------------------------------------------------------------
                                        IO
---------------------------------------------------------------------------------*/
        case T_IN:
        {
            int v = 0;
            scanf("%d", &v);
            char *name = strdup(_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                n->id.value = v;
                return 1;
            }
            else
            {
                printf("Variable %s does not exist", name);
                exit(0);
            }
        }

        case T_OUT:
            printf("%d", execNode(_node->stmt.op[0]));
            return 0;

        case T_OUTL:
        {
            int n1 = execNode(_node->stmt.op[0]);
            fprintf(yycmd, "printed value %d\n",  n1);
            printf("%d\n", n1);
            return 0;
        }
            

/*---------------------------------------------------------------------------------
                                     Arithmetic
---------------------------------------------------------------------------------*/
        case T_SUM:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "summed %d and %d\n",  n1, n2);
            return n1 + n2;
        }

        case T_NEGATIVE:
            return 0 - execNode(_node->stmt.op[0]);

        case T_SUB:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "subtracted %d and %d\n", n1, n2);
            return n1 - n2;
        }
        case T_MULT:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "multiplied %d and %d\n", n1, n2);
            return n1 * n2;
        }

        case T_DIV:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "divided %d and %d\n", n1, n2);
            return n1 / n2;
        }

        case T_MOD:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "calculated %d mod %d\n", n1, n2);
            return n1 % n2;
        }

/*---------------------------------------------------------------------------------
                                    Relational                                    
---------------------------------------------------------------------------------*/
        case T_GREAT:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is great than %d\n",  n1, n2);
            return n1 > n2;
        }
            

        case T_GE:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is great or equal than %d\n",  n1, n2);
            return n1 >= n2;
        }

        case T_LESS:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is less than %d\n",  n1, n2);
            return n1 < n2;
        }

        case T_LE:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is less or equal than %d\n",  n1, n2);
            return n1 <= n2;
        }

        case T_EQUAL:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is equal to %d\n",  n1, n2);
            return n1 == n2;
        }

        case T_DIF:
        {
            int n1 = execNode(_node->stmt.op[0]);
            int n2 = execNode(_node->stmt.op[1]);
            fprintf(yycmd, "checked if %d is different from %d\n",  n1, n2);
            return n1 != n2;
        }

/*---------------------------------------------------------------------------------
                                        Logical
---------------------------------------------------------------------------------*/
        case T_AND:
            return execNode(_node->stmt.op[0]) && execNode(_node->stmt.op[1]);

        case T_OR:
            return execNode(_node->stmt.op[0]) || execNode(_node->stmt.op[1]);

        case T_NOT:
            return !(execNode(_node->stmt.op[0]));

        default:
            return -3;
        }
    }
    return -2;
}