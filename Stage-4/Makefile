copy:
	cp output.xsm /home/ricky/xsm_expl/Stage-4/output.xsm
	cp final.xsm /home/ricky/xsm_expl/Stage-4/final.xsm
compile:
	@read -p "Enter Module Name:" module; \
    lex_file=$$module.l; \
	yacc_file=$$module.y; \
	output_file=$$module.exe; \
	yacc -d $$yacc_file; \
	lex $$lex_file; \
	gcc lex.yy.c y.tab.c -o $$output_file; \
	./$$output_file input.expl; \
	lex label_translator.l; \
	gcc lex.yy.c; \
	./a.out output.xsm 
run: 
	@cd /home/ricky/xsm_expl; \
	./xsm -l library.lib -e Stage-4/final.xsm