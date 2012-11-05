//
//  RootViewController.h
//  GCD
//
//  Created by 裴洪凯 on 12-10-8.
//  Copyright (c) 2012年 裴洪凯. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController
{
    NSMutableArray *arrayURL;
    NSMutableArray *arrayContent;
    NSMutableArray *arrayLabel;
}
- (IBAction)buttonGCDPress:(id)sender;
@property (strong, nonatomic) IBOutlet UIWebView *webView1;
@property (strong, nonatomic) IBOutlet UIWebView *webView2;
- (IBAction)button_applyPress:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *label1;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIView *view3;
@property (strong, nonatomic) IBOutlet UIView *view4;
@property (strong, nonatomic) IBOutlet UIProgressView *progress;
- (IBAction)timerPresss:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label4;
dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block);
@end
