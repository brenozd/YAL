#ifndef NODES_H
#define NODES_H

typedef enum
{
    t_Constant,
    t_Id,
    t_Statement,

} nodeEnum;

typedef enum
{
    d_INT,
    d_BOOL,
    d_FLOAT,
    d_CHAR,
    d_STRING
} data_type;

typedef struct _constNode
{
    int value;
    data_type type;
} constNode;

typedef struct _idNode
{
    int value;
    data_type type;
    char *name;
    struct _idNode *next;
} idNode;

typedef struct _stmtNode
{
    int opr;
    int num_operators;
    struct _node *op[3];
} stmtNode;

typedef struct _node
{
    nodeEnum type;
    struct _node *next;
    union
    {
        constNode cnt;
        idNode id;
        stmtNode stmt;
    };

} node;
#endif