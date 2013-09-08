//
//  ViewController.h
//  CatEye
//
//  Created by claire on 13-9-4.
//  Copyright (c) 2013年 claire. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"
#import "KxMovieGLView.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate>

@property (weak, nonatomic) IBOutlet UIView *searchView;
@property (weak, nonatomic) IBOutlet UILabel *searchLable;
@property (weak, nonatomic) IBOutlet UITableView *searchTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchLoading;

@property (weak, nonatomic) IBOutlet UIView *captureView;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIImageView *outputImage;

-(void)exit;
@end
