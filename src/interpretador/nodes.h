#ifndef NODES_H
#define NODES_H

extern int sym[26];
struct idNode *id_table = NULL;

typedef enum
{
    t_Constant,
    t_Id,
    t_Statement,
    t_Block
} nodeEnum;

typedef struct constNode
{
    int value;
} constNode;

typedef struct idNode
{
    char *name;
    int value;
    struct idNode *next;
} idNode;

typedef struct stmtNode
{
    int opr;
    int num_operators;
    struct nodeType *op[3];
} stmtNode;

typedef struct nodeTypeTag
{
    nodeEnum type;
    union
    {
        constNode cnt;
        idNode id;
        stmtNode stmt;
    };

} nodeType;
#endif