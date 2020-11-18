#include <stdio.h>
#include <math.h>
#include "nodes.h"
#include "../obj/YAL.tab.h"

#define sizeof_Node (((char *)&node->cnt - (char *)node))

nodeType *getsym(char const *name)
{
    for (idNode *p = id_table; p; p = p->next)
        if (strcmp(p->name, name) == 0)
            return p;
    return NULL;
}

nodeType *constant(int value)
{
    nodeType *node;
    size_t nodeSize;

    nodeSize = sizeof_Node + sizeof(constNode);
    if ((node = malloc(nodeSize)) == NULL)
        yyerror("Out of memory");
    node->type = t_Constant;
    node->cnt.value = value;
    return node;
}

nodeType *id(char const *name)
{
    char *_name = strdup(name);
    nodeType *node = getsym(_name);
    if (node == NULL)
    {
        size_t nodeSize;
        nodeSize = sizeof_Node + sizeof(idNode);
        if ((node = malloc(nodeSize)) == NULL)
            yyerror("Out of memory");
        node->type = t_Id;
        node->id.name = _name;
        node->id.next = id_table;
        id_table = &node->id;
    }
    return node;
}

nodeType *stmt(int opr, int num_operators, ...)
{
    va_list args;
    nodeType *node;
    size_t nodeSize;
    nodeSize = sizeof_Node + sizeof(stmtNode) + (num_operators - 1) * (sizeof(nodeType *));
    if ((node = malloc(nodeSize)) == NULL)
        yyerror("Out of memory");

    node->type = t_Statement;
    node->stmt.opr = opr;
    node->stmt.num_operators = num_operators;
    va_start(args, num_operators);
    for (size_t i = 0; i < num_operators; i++)
    {
        node->stmt.op[i] = va_arg(args, nodeType *);
    }
    va_end(args);
    return node;
}

void freeNode(nodeType *node)
{
    if (!node)
        return;

    if (node->type == t_Statement)
    {
        for (size_t i = 0; i < node->stmt.num_operators; i++)
        {
            freeNode(node->stmt.op[i]);
        }
    }
    free(node);
}

int execNode(nodeType *node)
{

    if (!node)
        return -1;

    switch (node->type)
    {
    case t_Constant:
        return node->cnt.value;
        break;

    case t_Id:
    {
        nodeType *n = getsym(node->id.name);
        return n != NULL ? n->cnt.value : -4;
        break;
    }

    case t_Block:
        break;

    case t_Statement:
        switch (node->stmt.opr)
        {
        case T_ASSGN:
        {
            char *name = strdup(node->stmt.op[0]);
            idNode *n = getsym(name);
            if (n != NULL)
            {
                n->value = execNode(node->stmt.op[1]);
                return 1;
            }
            else
            {
                printf("Variable %s does not exist", name);
            }
        }

        case T_EOS:
            execNode(node->stmt.op[0]);
            return execNode(node->stmt.op[1]);

        case T_WHILE:
            while (execNode(node->stmt.op[0]))
                execNode(node->stmt.op[1]);
            return 0;

        case T_IF:
            if (node->stmt.op[0])
                execNode(node->stmt.op[1]);
            else if (node->stmt.num_operators > 2)
                execNode(node->stmt.op[2]);
            return 0;

        case T_IN:
            return execNode(node->stmt.op[1]);

        case T_OUT:
            printf("%d", execNode(node->stmt.op[0]));
            return 0;

        case T_OUTL:
        {
            int val = execNode(node->stmt.op[0]);
            printf("%d\n", val);
            return 0;
        }

        case T_SUM:
            return execNode(node->stmt.op[0]) + execNode(node->stmt.op[1]);

        case T_NEGATIVE:
            return 0 - execNode(node->stmt.op[0]);

        case T_SUB:
            return execNode(node->stmt.op[0]) - execNode(node->stmt.op[1]);

        case T_MULT:
            return execNode(node->stmt.op[0]) * execNode(node->stmt.op[1]);

        case T_DIV:
            return execNode(node->stmt.op[0]) / execNode(node->stmt.op[1]);

        case T_MOD:
            return execNode(node->stmt.op[0]) % execNode(node->stmt.op[1]);

        case T_GREAT:
            return execNode(node->stmt.op[0]) > execNode(node->stmt.op[1]);

        case T_GE:
            return execNode(node->stmt.op[0]) >= execNode(node->stmt.op[1]);

        case T_LESS:
            return execNode(node->stmt.op[0]) < execNode(node->stmt.op[1]);

        case T_LE:
            return execNode(node->stmt.op[0]) <= execNode(node->stmt.op[1]);

        case T_EQUAL:
            return execNode(node->stmt.op[0]) == execNode(node->stmt.op[1]);

        case T_DIF:
            return execNode(node->stmt.op[0]) != execNode(node->stmt.op[1]);

        case T_AND:
            return execNode(node->stmt.op[0]) && execNode(node->stmt.op[1]);

        case T_OR:
            return execNode(node->stmt.op[0]) || execNode(node->stmt.op[1]);

        case T_NOT:
            return !(execNode(node->stmt.op[0]));

        default:
            return -3;
        }
    }
    return -2;
}