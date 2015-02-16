/*************************************************************************
    > File Name: entry.c
    > Author: Christian chen
    > Mail: freestyletime@foxmail.com
    > Created Time: 四 12/25 10:24:59 2014
 ************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void trim(char *str){
    char *start = str - 1;
    char *end = str;
    char *p = str;
    while(*p){
        switch(*p){
        case ' ':
        case '\r':
        case '\n': {
                if(start + 1==p)
                    start = p;
            }
            break;
        default:
            break;
        }
        ++p;
    }
    --p;
    ++start;
    if(*start == 0){
        *str = 0 ;
        return;
    }
    end = p + 1;
    while(p > start){
        switch(*p){
        case ' ':
        case '\r':
        case '\n': {
                if(end - 1 == p)
                    end = p;
            }
            break;
        default:
            break;
        }
        --p;
    }
    memmove(str,start,end-start);
    *(str + (int)end - (int)start) = 0;
}

char* cmd_system(const char* command){
    char *result = (char*)malloc(1000*sizeof(char));
    FILE *fpRead;
    fpRead = popen(command, "r");
    char buf[1024];
    memset(buf,'\0',sizeof(buf));
    while(fgets(buf, 1024 - 1, fpRead)!=NULL){
        result = buf;
    }
    if(fpRead!=NULL)
        pclose(fpRead);
    return result;
}

int main(int argc, char *argv[]){

	if(argc < 7)return 0;
	char *model = argv[1];
	char *firmware = argv[2];
	char *mac = argv[3];
	char *sn = argv[4];
	char *time = argv[5];
	char *noncestr = argv[6];
	char *data = "";
	if(argc >= 8) data = argv[7];	

    char command1[128];
    char command2[128];
    char command3[256];
    char command4[256];
    char *result1 = (char*)malloc(500*sizeof(char));
    char *result2 = (char*)malloc(500*sizeof(char));
    char *result3 = (char*)malloc(500*sizeof(char));
    char *s = (char*)malloc(1000*sizeof(char));

    sprintf(command1, "echo -n '%s%s%s%s%s'|md5sum|cut -d ' ' -f1", model, firmware, mac, sn, time);
    strcpy(result1, cmd_system(command1));
    trim(result1);

    sprintf(command2, "echo -n '%s%s%s'|md5sum|cut -d ' ' -f1", data, noncestr, time);
    strcpy(result2, cmd_system(command2));
    trim(result2);

    strcat(s, result1);
    strcat(s, result2);

    sprintf(command3, "echo -n '%s'|md5sum|cut -d ' ' -f1", s);
    strcpy(result3, cmd_system(command3));
    trim(result3);

    sprintf(command4, "echo -n '%s'|md5sum|cut -d ' ' -f1", result3);
    system(command4);

    free(result1);
    free(result2);
    free(result3);
    free(s);

	return 0;
}
