compile:
	yacc -d types.y; \
	lex types.l; \
	gcc lex.yy.c y.tab.c -o types.exe
copy:
	cp output.xsm /home/ricky/xsm_expl/Stage-6/output.xsm
	cp final.xsm /home/ricky/xsm_expl/Stage-6/final.xsm
	cp library.lib /home/ricky/xsm_expl/library.lib