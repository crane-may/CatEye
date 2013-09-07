//
//  VideoFrameBuf.m
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import "VideoFrameBuf.h"

#define VIDEOBUFLEN 10
#define DROP NSLog(@"drop a frame")

static VideoFrame video_bufs_real[VIDEOBUFLEN];
static VideoFrame *video_bufs[VIDEOBUFLEN];

NSMutableString *lock;

void init_frame(VideoFrame *frame){
    frame->data_len = 0;
    frame->frame_seq = 0;
    frame->pkg_count = 0;
    frame->isFinish = 0;
}

void init_video_buf(){
    lock = [NSMutableString stringWithString:@"lock"];
    for (int i = 0; i < VIDEOBUFLEN; i++ ) {
        video_bufs[i] = video_bufs_real + i;
        init_frame(video_bufs[i]);
    }
}

void top_finish(){ }

void insert_at_top(){
    @synchronized(lock){
        VideoFrame *bottom = video_bufs[VIDEOBUFLEN - 1];
        for (int i=VIDEOBUFLEN - 1; i>0; i--) {
            video_bufs[i] = video_bufs[i-1];
        }
        video_bufs[0] = bottom;
    }
    init_frame(video_bufs[0]);
}

void insert_data(NSData *data){
    int arg3[3];
    int frame_seq, pkg_seq, start01_end10;
    
    [data getBytes:arg3 range:NSMakeRange(0, 12)];
    frame_seq = CFSwapInt32BigToHost(arg3[0]);
    pkg_seq = CFSwapInt32BigToHost(arg3[1]);
    start01_end10 = CFSwapInt32BigToHost(arg3[2]);
    
    VideoFrame *top = video_bufs[0];
    
    if (frame_seq > top->frame_seq && (start01_end10 & 0x1)) {
        insert_at_top();
        top = video_bufs[0];
        top->frame_seq = frame_seq;
    }
    
    if (frame_seq == top->frame_seq) {
        if (top->pkg_count == pkg_seq) {
            [data getBytes:top->data + top->data_len range:NSMakeRange(12, data.length - 12)];
            top->pkg_count++;
            top->data_len += ([data length] - 12);
            
            if (start01_end10 & 0x2) {
                top->isFinish = YES;
                top_finish();
            }
        }else DROP;
    }else DROP;
}

VideoFrame *get_frame(){
    VideoFrame *ret = nil;
    @synchronized(lock){
        for (int i=VIDEOBUFLEN - 1; i>0; i--) {
            if (video_bufs[i]->isFinish) {
                ret = video_bufs[i];
                video_bufs[i]->isFinish = 0;
                break;
            }
        }
    }
    return ret;
}
