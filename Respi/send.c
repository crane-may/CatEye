#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio>

static char send_pkt[1412];
static char read_buf[100];

static char *buf;
static int buf_len = 0;

static int frame_seq = -1;
static int pkg_seq = 0;

void send_pkt(int is_finish){
    if (buf_len == 0) return;
    
    //TO DO
    
    pkg_seq++;
}

void scan_read_buf(int len){
    static int last_zero = 0;
    for (int i = 0; i < len; i++){
        char c = read_buf[i];
        
        if (last_zero == 3 && c == 1){
            send_pkt(1);
            frame_seq++;
            pkg_seq = 0;
            buf = send_pkt + 12;
        }
        
        if (c != 0) {
            if (buf_len + last_zero + 1 > 1400) send_pkt(0);
            
            if (last_zero > 0) {
                bzero(buf, last_zero);
                buf+=last_zero;
            }
            
            *buf = c;
            buf++;
            
            last_zero=0;
        }else{
            last_zero++;
        }
    }
}

int main(){
    while (1){
        int n = fread(read_buf,1,100,stdin);
        if (!n) {
            usleep(1000);
        }else{
            scan_read_buf(n);
        }
    }
}
