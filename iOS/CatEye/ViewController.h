//
//  ViewController.h
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

@interface ViewController : UIViewController{
	AVFormatContext *pFormatCtx;
	AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    AVPacket packet;
	AVPicture picture;
	int videoStream;
	struct SwsContext *img_convert_ctx;
	int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
	UIImage *currentImage;
	double duration;
    double currentTime;
}
@property (weak, nonatomic) IBOutlet UIImageView *outputImage;

@end
