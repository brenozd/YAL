#####################
##Compiler Settings##
#####################
LEX = flex
LEX_FLAGS = -o
YACC = bison
YACC_FLAGS = -dtv -o

CXX = gcc
CXX_FLAGS = -g
LD_FLAGS = 
APPNAME = YAL

#####################
#### Dir Settings ###
#####################
BIN = bin
SRC = src
OBJ = obj

#####################
## Target Variables #
#####################
EXT = .l
SRC_FILES = $(wildcard $(SRC)/*$(EXT))
LEX_FILES = $(SRC_FILES:$(SRC)/%$(EXT)=$(OBJ)/%.yy.c)
YACC_FILES = $(SRC_FILES:$(SRC)/%$(EXT)=$(OBJ)/%.tab.c)
#####################
###### Targets ######
#####################
all: cleand $(APPNAME) run

# Build Application
$(APPNAME) : $(LEX_FILES) $(YACC_FILES)
	@echo "🚧 Building..."
	$(CXX) $(CXX_FLAGS) $^ -o  $(BIN)/$@.out $(LD_FLAGS)

#Run executable
.PHONY: run
run:
	clear
	@echo "🚀 Running..."
	./$(BIN)/$(APPNAME).out

#Clean executable
.PHONY: clean
clean:
	@echo "🧹 Cleaning executable..."
	-rm $(BIN)/*

#Clean dependencies
.PHONY: cleand
cleand:
	@echo "🧹 Cleaning dependencies..."
	-rm $(OBJ)/*.yy.c $(OBJ)/*.tab.c $(OBJ)/*.tab.h $(OBJ)/*.output $(BIN)/*

#Create yy.c file
.PHONY: lex
$(OBJ)/%.yy.c: $(SRC)/%.l
	$(LEX) $(LEX_FLAGS) $@ $<

#Create .tab.c file
.PHONY: bison
$(OBJ)/%.tab.c: $(SRC)/%.y
	$(YACC) $(YACC_FLAGS) $@ $<