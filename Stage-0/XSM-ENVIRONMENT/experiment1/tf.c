#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE* target_file;
    target_file = fopen("tf.xsm", "w+");
    fprintf(target_file, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n%d\n", 0, 2056, 0, 0, 0, 0, 0, 0);
    fprintf(target_file, "BRKP\n");
    fprintf(target_file, "MOV R0, 3\n");
    fprintf(target_file, "MOV R1, 2\n");
    fprintf(target_file, "ADD R0, R1\n");
    fclose(target_file);
    return 0;
}