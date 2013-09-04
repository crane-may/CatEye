//
//  VideoFrameBuf.h
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

typedef struct{
    char data[128 * 1024];
    int data_len;
    int frame_seq;
    int pkg_count;
    int isFinish;
} VideoFrame;

void init_video_buf();
void insert_data(NSData *data);
VideoFrame *get_frame();

