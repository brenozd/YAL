#ifndef NODES_H
#define NODES_H

typedef struct _idNode idNode;
typedef struct _constNode constNode;
typedef struct _stmtNode stmtNode;
typedef struct _node node;

extern int sym[26];


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
};

typedef struct _idNode
{
    int value;
    data_type type;
    char *name;
    idNode *next;
};

typedef struct _stmtNode
{
    int opr;
    int num_operators;
    node *op[2];
};

struct _node
{
    nodeEnum type;
    union
    {
        constNode cnt;
        idNode id;
        stmtNode stmt;
    };

};


#endif