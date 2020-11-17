#include <stdio.h>
#include <math.h>
#include "nodes.h"
#include "../obj/YAL.tab.h"

int execNode(nodeType *node)
{

    if (!node)
        return -1;

    switch (node->type)
    {
    case Constant:
        return node->cnt.value;
        break;

    case Id:
        return sym[node->id.value];
        break;

    case Statement:
        switch (node->stmt.opr)
        {
        case T_ASSGN:
            return sym[node->stmt.op[0]->id.value] =
                       execNode(node->stmt.op[1]);

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
            printf("%d\n", execNode(node->stmt.op[0]));
            return 0;

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
        }
    }
    return -2;
}