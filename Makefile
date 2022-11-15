EXEC = cmp
FILES = src/arithmetic.tab.c src/lex.yy.c

all: $(EXEC)

$(EXEC): auto-generated/lex.yy.c auto-generated/arithmetic.tab.c
	$(CC) -ggdb $^ -o $@

auto-generated/arithmetic.tab.c : src/arithmetic.y auto-generated
	bison -r all -d $< -o $@

auto-generated/lex.yy.c : src/arithmetic.l auto-generated
	flex -o $@ $<

auto-generated:
	mkdir $@

tests: $(EXEC) test
	./test

test: src/test.c
	$(CC) -ggdb $^ -o $@

clean:
	$(RM) -rf auto-generated output
	$(RM) $(EXEC)
	$(RM) test
