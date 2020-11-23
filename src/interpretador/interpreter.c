#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <math.h>
#include "nodes.h"
#include "../../obj/YAL.tab.h"

#define sizeof_Node (sizeof(nodeEnum) + sizeof(node *))

//Pointer to a chain-structure (symbol table)
node *id_table = NULL;
//Pointer to a chain-structure with all nodes allocated
node *node_list = NULL;

extern FILE *yycmd;
extern int n_line;
extern void yyerror(const char *s);

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
    for (node *p = id_table; p; p = p->next)
    {
        printf("[%s, %lf]\n", p->id.name, p->id.data.num);
    }
}

//Create a constant node to store value
node *constant(dataValue t_data, int type)
{
    node *_node = NULL;
    size_t nodeSize;
    nodeSize = sizeof_Node + sizeof(constNode);
    if ((_node = (node*)malloc(nodeSize)) == NULL)
        yyerror("Out of memory");

    _node->type = t_Constant;

    _node->next = node_list;
    node_list = _node;

    _node->cnt.type = type;
    if (_node->cnt.type == d_NUMBER)
    {
        _node->cnt.data.num = t_data.num;
        fprintf(yycmd, "creating constant %lf\n", _node->cnt.data.num);
    }
    else
    {
        _node->cnt.data.str = strdup(t_data.str);
        fprintf(yycmd, "creating constant %s\n",  _node->cnt.data.str);
    }
    return _node;
}

//Create a id node to store a variable type
node *id(char const *name, int type)
{
    char *_name = strdup(name);
    node *_node = getSymbol(_name);
    if (_node == NULL)
    {
        size_t nodeSize;
        nodeSize = sizeof_Node + 8 + sizeof(idNode);
        if ((_node = (node*)malloc(nodeSize)) == NULL)
            yyerror("Out of memory");

        _node->type = t_Id;
        _node->id.name = strdup(_name);

        _node->id.type = type;
        if (_node->id.type == d_NUMBER)
            _node->id.data.num = 0;
        else
            _node->id.data.str = "";

        _node->id.next = id_table;
        id_table = _node;
        _node->next = node_list;
        node_list = _node;

        fprintf(yycmd, "creating variable %s\n", _name);
    }
    else
    {
        printf("In line: %d, variable %s already exist\n", n_line, _name);
        exit(0);
    }
    free(_name);
    return _node;
}

//Create a statement node
node *stmt(int opr, int num_operators, ...)
{
    va_list args;
    node *_node = NULL;
    size_t nodeSize;
    nodeSize = sizeof_Node + sizeof(stmtNode) + (num_operators - 1) * (sizeof(stmtNode *));
    if ((_node = (node*)malloc(nodeSize)) == NULL)
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
    if (_node->next != NULL)
        freeNode(_node->next);
    free(_node);
}

//Execute node based on node type and flag
dataValue execNode(node *_node)
{
    dataValue r;
    if (!_node)
    {
        r.num = 0;
        return r;
    }
        

    switch (_node->type)
    {

    case t_Constant:
        return _node->cnt.data;
        break;

    case t_Id:
    {
        node *n = getSymbol(_node->id.name);
        if (n != NULL)
            return n->id.data;
        else
            yyerror("Variable does not exist");
    }

    case t_Statement:
        switch (_node->stmt.opr)
        {
/*---------------------------------------------------------------------------------
                                Assign and compose
---------------------------------------------------------------------------------*/
        case T_ASSGN:
        {
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                switch (n->id.type)
                {
                case d_NUMBER:
                {
                    dataValue v = execNode(_node->stmt.op[1]);
                    fprintf(yycmd, "assigned value %lf to %s\n", v.num, n->id.name);
                    return n->id.data = v;
                }
                case d_STRING:
                {
                    dataValue v = execNode(_node->stmt.op[1]);
                    fprintf(yycmd, "assigned value %s to %s\n", v.str, n->id.name);
                    return n->id.data = v;
                }
                
                default:
                    break;
                }
                
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_SUME:
        {
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                dataValue v = execNode(_node->stmt.op[1]);
                
                n->id.data.num += v.num;
                r.num = n->id.data.num;
                fprintf(yycmd, "summed value %lf to %s\n", v.num, n->id.name);
                return r;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_SUBE:
        {
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                dataValue v = execNode(_node->stmt.op[1]);
                
                n->id.data.num -= v.num;
                r.num = n->id.data.num;
                fprintf(yycmd, "subtracted value %lf from %s\n", v.num, n->id.name);
                return r;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_MULTE:
        {
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                dataValue v = execNode(_node->stmt.op[1]);
                
                n->id.data.num *= v.num;
                r.num = n->id.data.num;
                fprintf(yycmd, "multiplied value from %s by %lf\n", n->id.name, v.num);
                return r;
            }
            else
            {
                printf("Variable %s does not exist\n", name);
                exit(0);
            }
        }

        case T_DIVE:
        {
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                dataValue v = execNode(_node->stmt.op[1]);
                
                n->id.data.num /= v.num;
                r.num = n->id.data.num;
                fprintf(yycmd, "divided value %lf by %lf\n", v.num, n->id.data.num);
                return r;
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
        {
            while (execNode(_node->stmt.op[0]).num != 0)
                execNode(_node->stmt.op[1]);
            return r;
        }
            

        case T_IF:
        {
            fprintf(yycmd, "if statement with condition ");
            
            r.num = 0;
            if (execNode(_node->stmt.op[0]).num)
                execNode(_node->stmt.op[1]);
            else if (_node->stmt.num_operators > 2)
                execNode(_node->stmt.op[2]);
            return r;
        }

/*---------------------------------------------------------------------------------
                                        IO
---------------------------------------------------------------------------------*/
        case T_IN:
        {
            double v = 0;
            scanf("%lf", &v);
            char *name = strdup((char*)_node->stmt.op[0]);
            node *n = getSymbol(name);
            if (n != NULL)
            {
                n->id.data.num = v;
                return n->id.data;
            }
            else
            {
                printf("Variable %s does not exist", name);
                exit(0);
            }
        }

        case T_OUT:
        {
            node *n = _node->stmt.op[0];
            dataValue n1 = execNode(n);
            if ((n->cnt.type == d_NUMBER) || (n->id.type == d_NUMBER))
            {
                fprintf(yycmd, "printed %lf\n", n1.num);
                printf("%lf", n1.num);
            }
            else
            {
                fprintf(yycmd, "printed %s\n", n1.str);
                printf("%s", n1.str);
            }
            
            return n1;
        }

        case T_OUTL:
        {
            node *n = _node->stmt.op[0];
            dataValue n1 = execNode(n);
            if ((n->cnt.type == d_NUMBER) || (n->id.type == d_NUMBER))
            {
                fprintf(yycmd, "printed %lf\n", n1.num);
                printf("%lf\n", n1.num);
            }
            else
            {
                fprintf(yycmd, "printed %s\n", n1.str);
                printf("%s\n", n1.str);
            }
            
            return n1;
        }

/*---------------------------------------------------------------------------------
                                     Arithmetic
---------------------------------------------------------------------------------*/
        case T_SUM:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num + n2.num;
            fprintf(yycmd, "summed %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_NEGATIVE:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            r.num =  0 - n1.num;
            return r;
        }
            

        case T_SUB:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num - n2.num;
            fprintf(yycmd, "subtracted %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_MULT:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num * n2.num;
            fprintf(yycmd, "multiplied %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_DIV:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num / n2.num;
            fprintf(yycmd, "divided %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_MOD:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = fmod(n1.num, n2.num);
            fprintf(yycmd, "calculated %lf mod %lf\n", n1.num, n2.num);
            return r;
        }

/*---------------------------------------------------------------------------------
                                    Relational                                    
---------------------------------------------------------------------------------*/
        case T_GREAT:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num > n2.num;
            fprintf(yycmd, "checked if %lf is great than %lf\n", n1.num, n2.num);
            return r;
        }

        case T_GE:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num >= n2.num;
            fprintf(yycmd, "checked if %lf is great or equal than %lf\n", n1.num, n2.num);
            return r;
        }

        case T_LESS:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num < n2.num;
            fprintf(yycmd, "checked if %lf is less than %lf\n", n1.num, n2.num);
            return r;
        }

        case T_LE:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num <= n2.num;
            fprintf(yycmd, "checked if %lf is less or equal than %lf\n", n1.num, n2.num);
            return r;
        }

        case T_EQUAL:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num == n2.num;
            fprintf(yycmd, "checked if %lf is equal to %lf\n", n1.num, n2.num);
            return r;
        }

        case T_DIF:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num == n2.num;
            fprintf(yycmd, "checked if %lf is different from %lf\n", n1.num, n2.num);
            return r;
        }

/*---------------------------------------------------------------------------------
                                        Logical
---------------------------------------------------------------------------------*/
        case T_AND:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num && n2.num;
            fprintf(yycmd, "logical AND between %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_OR:
        {
            dataValue n1 = execNode(_node->stmt.op[0]);
            dataValue n2 = execNode(_node->stmt.op[1]);
            r.num = n1.num || n2.num;
            fprintf(yycmd, "logical OR between %lf and %lf\n", n1.num, n2.num);
            return r;
        }

        case T_NOT:
            {
            dataValue n1 = execNode(_node->stmt.op[0]);
            r.num = !n1.num;
            fprintf(yycmd, "denied %lf\n", n1.num);
            return r;
        }

        default:
            r.num = -3;
            return r;
        }
    }
    r.num = -2;
    return r;
}