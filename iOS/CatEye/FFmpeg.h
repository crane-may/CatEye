//
//  FFmpeg.h
//  CatEye
//
//  Created by claire on 13-9-7.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
@class ViewController;

@interface FFmpeg : NSObject{
    AVFormatContext *pFormatCtx;
	AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    AVPacket packet;
	AVPicture picture;
	int videoStream;
	struct SwsContext *img_convert_ctx;
	int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
}

@property (weak, nonatomic) ViewController *view;

-(void)initffmpeg;
-(void)decodeAndShow : (char*) buf length:(int)len;
@end
