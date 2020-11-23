#ifndef NODES_H
#define NODES_H

typedef enum
{
    t_Constant,
    t_Id,
    t_Statement

} nodeEnum;

typedef enum _dataType
{
    d_NUMBER = 0,
    d_STRING
} dataType;

typedef union _dataValue
{
    char *str;
    double num;
} dataValue;

typedef struct _constNode
{
    dataType type;
    dataValue data;
} constNode;

typedef struct _idNode
{

    char *name;
    dataType type;
    dataValue data;

    struct _node *next;
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