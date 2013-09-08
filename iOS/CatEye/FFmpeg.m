//
//  FFmpeg.m
//  CatEye
//
//  Created by claire on 13-9-7.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import "FFmpeg.h"
#import "ViewController.h"

@implementation FFmpeg

-(void)initffmpeg
{
    AVCodec *pCodec;
    
    av_register_all();
    av_init_packet(&packet);
    pCodec=avcodec_find_decoder(CODEC_ID_H264);
    if(pCodec==NULL)
        goto initError; // Codec not found
    
    pCodecCtx = avcodec_alloc_context3(pCodec);
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec,NULL) < 0)
        goto initError; // Could not open codec
    
    
    pFrame = avcodec_alloc_frame();
    
    NSLog(@"init success");
    return;
    
initError:
    //error action
    NSLog(@"init failed");
    return ;
}

-(void)releaseFFMPEG
{
    // Free scaler
    sws_freeContext(img_convert_ctx);
    
    // Free RGB picture
    avpicture_free(&picture);
    
    // Free the YUV frame
    av_free(pFrame);
    
    // Close the codec
    if (pCodecCtx) avcodec_close(pCodecCtx);
}

-(void)setupScaler {
    
    // Release old picture and scaler
    avpicture_free(&picture);
    sws_freeContext(img_convert_ctx);
    
    // Allocate RGB picture
    avpicture_alloc(&picture, PIX_FMT_RGB24,pCodecCtx->width,pCodecCtx->height);
    
    // Setup scaler
    static int sws_flags =  SWS_FAST_BILINEAR;
    img_convert_ctx = sws_getContext(pCodecCtx->width,
                                     pCodecCtx->height,
                                     pCodecCtx->pix_fmt,
                                     pCodecCtx->width,
                                     pCodecCtx->height,
                                     PIX_FMT_RGB24,
                                     sws_flags, NULL, NULL, NULL);
    
}

-(void)convertFrameToRGB
{
    [self setupScaler];
    sws_scale (img_convert_ctx, (const uint8_t *const *)(pFrame->data), pFrame->linesize,
               0, pCodecCtx->height,
               picture.data, picture.linesize);
}


-(void)decodeAndShow : (char*) buf length:(int)len
{
    packet.size = len;
    packet.data = (unsigned char *)buf;
    int got_picture_ptr=0;
    int nImageSize;
    nImageSize = avcodec_decode_video2(pCodecCtx,pFrame,&got_picture_ptr,&packet);
//    NSLog(@"nImageSize:%d--got_picture_ptr:%d",nImageSize,got_picture_ptr);
    
    if (nImageSize > 0 )
    {
        if (pFrame->data[0])
        {
            [self convertFrameToRGB];
            int nWidth = pCodecCtx->width;
            int nHeight = pCodecCtx->height;
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
            CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, picture.data[0], nWidth*nHeight*3,kCFAllocatorNull);
            CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            
            CGImageRef cgImage = CGImageCreate(nWidth,
                                               nHeight,
                                               8,
                                               24,
                                               nWidth*3,
                                               colorSpace,
                                               bitmapInfo,
                                               provider,
                                               NULL,
                                               YES,
                                               kCGRenderingIntentDefault);
            CGColorSpaceRelease(colorSpace);
            //UIImage *image = [UIImage imageWithCGImage:cgImage];
            UIImage* image = [[UIImage alloc]initWithCGImage:cgImage];   //crespo modify 20111020
            CGImageRelease(cgImage);
            CGDataProviderRelease(provider);
            CFRelease(data);
            // [self timeIntervalControl:ulTime]; //add 0228
            [self performSelectorOnMainThread:@selector(showImage:) withObject:image waitUntilDone:YES];
        }
    }
    return;
}

-(void)showImage:(UIImage *)img
{
    _view.outputImage.image = img;
}


@end
