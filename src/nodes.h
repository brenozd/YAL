#ifndef NODES_H
#define NODES_H

extern int sym[26];

typedef enum {
    Constant,
    Id,
    Statement
} nodeEnum;

typedef struct {
    int value;
} constNode;

typedef struct {
    int value;
} idNode;

typedef struct {
    int opr;
    int num_operators;
    struct nodeTag *op[1];
} stmtNode;

typedef struct nodeTag {
    nodeEnum type;

    union
    {
        constNode cnt;
        idNode id;
        stmtNode stmt;
    };
    
} nodeType;
#endif