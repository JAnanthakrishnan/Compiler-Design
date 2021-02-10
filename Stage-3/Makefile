generate:
	cp output.xsm /home/ak/xsm_expl/Stage-3/output.xsm
compile:
	@read -p "Enter Module Name:" module; \
    lex_file=$$module.l; \
	yacc_file=$$module.y; \
	output_file=$$module.exe; \
	lex $$lex_file; \
	yacc -d $$yacc_file; \
	gcc lex.yy.c y.tab.c -o $$output_file; \
	./$$output_file input.expl; \
	cp output.xsm /home/ak/xsm_expl/Stage-3/output.xsm
run: 
	@cd /home/ak/xsm_expl ;\
	./xsm -l Stage-0/library.lib -e Stage-3/output.xsm