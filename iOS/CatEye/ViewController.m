//
//  ViewController.m
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import "ViewController.h"
#import "VideoFrameBuf.h"
#import "FFmpeg.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#import <AdSupport/ASIdentifierManager.h>


@interface ViewController ()
@property (strong, nonatomic) GCDAsyncUdpSocket *discoverSocket;
@property (strong, nonatomic) GCDAsyncUdpSocket *captureSocket;
@property (strong, nonatomic) GCDAsyncSocket *connSocket;
@property (strong, nonatomic) FFmpeg *ffmpeg;
@property (strong, atomic) NSMutableArray *eyes;

@property BOOL is_capturing;
@property int frame_count;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _ffmpeg = [[FFmpeg alloc] init];
    _ffmpeg.view = self;
    [_ffmpeg initffmpeg];
    _is_capturing = NO;
    
    _searchTable.delegate = self;
    _searchTable.dataSource = self;
    _eyes = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    _discoverSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    int port = 9527;
    if (![_discoverSocket bindToPort:port error:&error]){
        NSLog(@"Error starting server (bind): %@", error);return;
    }
    if (![_discoverSocket beginReceiving:&error]) {
        [_discoverSocket close];
        NSLog(@"Error starting server (recv): %@", error);return;
    }
    
    [self send_searching];
}

-(NSString *)thisName{
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

-(void)send_searching
{
    int fd, err;
    struct sockaddr_in  addr;
    NSData *            data;
    static const int    kOne = 1;
    
    fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) { NSLog(@"can't create socket");return;}
    err = setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &kOne, sizeof(kOne));
    if (err != 0) { NSLog(@"can't open socket");return;}
    
    data = [[NSString stringWithFormat:@"?eye@%@", [self thisName]] dataUsingEncoding:NSUTF8StringEncoding];
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_len = sizeof(addr);
    addr.sin_port = htons(9527);
    addr.sin_addr.s_addr = htonl(0xffffffff);  // 255.255.255.255
    
    sendto(fd, [data bytes], [data length], 0, (const struct sockaddr *) &addr, sizeof(addr));
    close(fd);
    
    [self performSelector:@selector(searchOver) withObject:self afterDelay:3];
    [_searchLoading startAnimating];
}


-(void)searchOver{
    if (_eyes.count > 0) {
        [_searchTable reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationBottom];
        [_searchLoading stopAnimating];
        _searchLable.text = [NSString stringWithFormat:@"Found %d eyes:", _eyes.count];
    }else{
        [self send_searching];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (sock == _discoverSocket) {
        NSString *stringdata = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (! [stringdata hasSuffix:[NSString stringWithFormat:@"@%@", [self thisName]]]) {
            struct sockaddr_storage sa;
            socklen_t salen = sizeof(sa);
            [address getBytes:&sa length:salen];
            
            char host[NI_MAXHOST];
            getnameinfo((struct sockaddr *)&sa, salen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
            NSString *ipAddress = [[NSString alloc] initWithBytes:host length:strlen(host) encoding:NSUTF8StringEncoding];
            NSLog(@"%@ - %@", stringdata, ipAddress);
            
            [_eyes addObject:ipAddress];
        }
    }
    //    insert_data(data);
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {return _eyes.count;};
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 64; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1.0f];
    cell.textLabel.textColor = [UIColor colorWithRed:143.0f/255.0f green:158.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
    cell.textLabel.text = [_eyes objectAtIndex:indexPath.row];
    return cell;
}

-(void)eyeView
{
    [self.view exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
    [UIView beginAnimations:@"animation" context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    [UIView commitAnimations];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self connect_eye:[_eyes objectAtIndex:indexPath.row]];
}

-(void)connect_eye:(NSString *)addr
{
    _connSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    
    if(![_connSocket connectToHost:addr onPort:9528 error:&err]){
        NSLog(@"Error: %@", err);
    }
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"did read data");
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"did connect");
    [self performSelectorInBackground:@selector(eyeView) withObject:nil];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"did disconnect");
}

- (IBAction)do_play:(id)sender {
}

-(void)start_capture{
    _frame_count = 0;
    init_video_buf();
    [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(tryDraw) userInfo:nil repeats:YES];
}

-(void)tryDraw
{
    VideoFrame *fme = get_frame();
    if (fme) {
        NSLog(@"%d",_frame_count++);
        [_ffmpeg decodeAndShow:fme->data length:fme->data_len];
    }
}


@end
