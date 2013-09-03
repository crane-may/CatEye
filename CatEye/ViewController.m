//
//  ViewController.m
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"

static char _buffer[15*1024*1024];

@interface ViewController ()
@property (strong, nonatomic) GCDAsyncUdpSocket *udpSocket;
@property int receive_count;
@property int buf_len;
@property int start_index;
@property int end_index;
@property int frame_count;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initffmpeg];
    
    _frame_count = 0;
    _receive_count = 0;
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    int port = 1234;
    if (![_udpSocket bindToPort:port error:&error]){
        NSLog(@"Error starting server (bind): %@", error);
        return;
    }
    if (![_udpSocket beginReceiving:&error]) {
        [_udpSocket close];
        NSLog(@"Error starting server (recv): %@", error);
        return;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:1.0/26
									 target:self
								   selector:@selector(tryDraw)
								   userInfo:nil
									repeats:YES];
}


-(void)tryDraw
{
    if (_buf_len < _end_index + 4) return;
    
    while (_buf_len > _end_index + 4 &&
           !(_buffer[_end_index] == 0 && _buffer[_end_index+1] == 0 && _buffer[_end_index+2] == 0 && _buffer[_end_index+3] == 1) ) {
        _end_index++;
    }
    
    if (_buf_len > _end_index + 4) {
        NSLog(@"frame: %d, pos: %d, len: %d",_frame_count, _start_index, _end_index - _start_index);
        [self decodeAndShow:_buffer + _start_index length:_end_index - _start_index andTimeStamp:0];
        
        _start_index = _end_index;
        _end_index++;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (_receive_count == 0 ) {
        char tmp_buf[4];
        [data getBytes:tmp_buf length:4];
        
        if (tmp_buf[0] == 0 && tmp_buf[1] == 0 && tmp_buf[2] == 0 && tmp_buf[3] == 1) {
            _start_index = 0;
            _end_index = 1;
            [data getBytes:_buffer length:data.length];
            _buf_len = data.length;
            
            _receive_count++;
        }
    }
    else if (_receive_count > 0 && _buf_len < sizeof(_buffer)){
        [data getBytes:_buffer + _buf_len length:data.length];
        _buf_len += data.length;
        _receive_count++;
    }
    
    NSLog(@"%d",_receive_count);
}

///////////////////////

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


-(void)decodeAndShow : (char*) buf length:(int)len andTimeStamp:(unsigned long)ulTime
{
    packet.size = len;
    packet.data = (unsigned char *)buf;
    int got_picture_ptr=0;
    int nImageSize;
    nImageSize = avcodec_decode_video2(pCodecCtx,pFrame,&got_picture_ptr,&packet);
    NSLog(@"nImageSize:%d--got_picture_ptr:%d",nImageSize,got_picture_ptr);
    
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
    _outputImage.image = img;
}



@end
