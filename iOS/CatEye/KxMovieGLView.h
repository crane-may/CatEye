//
//  ESGLView.h
//  kxmovie
//
//  Created by Kolyvan on 22.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

typedef enum {
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
    
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    
} KxVideoFrameFormat;


@interface KxVideoFrame : NSObject
@property (readwrite, nonatomic) KxVideoFrameFormat format;
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end

@interface KxVideoFrameYUV : KxVideoFrame
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@end

@interface KxMovieGLView : UIView{
	AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    AVPacket packet;
}

- (id) initWithFrame:(CGRect)frame;

-(void)setSizeWidth:(float)width height:(float)height;
- (void)render:(char*) buf length:(int)len;

@end
