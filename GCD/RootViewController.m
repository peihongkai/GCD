//
//  RootViewController.m
//  GCD
//
//  Created by 裴洪凯 on 12-10-8.
//  Copyright (c) 2012年 裴洪凯. All rights reserved.
//

#import "RootViewController.h"
#include "fcntl.h"

void test (void);
void (*function)(void);

@implementation RootViewController
@synthesize label3;
@synthesize label4;
@synthesize label1;
@synthesize label;
@synthesize view3;
@synthesize view4;
@synthesize progress;
@synthesize webView1;
@synthesize webView2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        arrayURL = [[NSMutableArray alloc] initWithObjects:@"http://www.hao123.com/favicon.ico",@"http://www.baidu.com/favicon.ico",@"http://www.sina.com/favicon.ico",@"http://www.sohu.com/favicon.ico", nil];
    }
    return self;
}
void test(void)
{
    printf("12344556");
};
- (void)viewDidLoad
{
    [super viewDidLoad];
    arrayContent = [[NSMutableArray alloc] init];
    [arrayContent addObject:webView1];
    [arrayContent addObject:webView2];
    [arrayContent addObject:view3];
    [arrayContent addObject:view4];
    
    arrayLabel = [[NSMutableArray alloc] initWithObjects:label,label1,label3,label4, nil];
    
    //用户事件
    dispatch_source_t source1 = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source1, ^{
        
        //---------------------------
        //延迟执行        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSLog(@"延迟2秒后执行，只执行一次");
        });
        //---------------------------
    });
    dispatch_resume(source1);
    
    dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        dispatch_source_merge_data(source1, 1);
    });
    
    //-------------------------------------------------------------------------------------------------------------------
    //从文件中读数据
    int file = open("/Users/peihongkai/Desktop/GCD/d.plist", O_RDONLY);
    
    fcntl(file, F_SETFL,O_NONBLOCK);

    dispatch_source_t sourceReader = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                                            file,
                                                            0,
                                                            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_event_handler(sourceReader, ^{
        
        size_t estimated = dispatch_source_get_data(sourceReader)+1;
        char buffer[estimated];
        NSLog(@"%ld",dispatch_source_get_handle(sourceReader));
        int len = read(file, buffer, sizeof(buffer));
//        write(STDOUT_FILENO, buffer, sizeof(buffer));
        if (len>0)
        {
            NSString *string2 = [[NSString alloc] initWithCString:buffer encoding:NSUTF8StringEncoding];
            NSLog(@"%@",string2);
//            NSLog(@"%d",len);
        }
    });
    //开始读取,先根据file descriptor读取内容，将得到的文件长度放到自身的data中（int型），然后在将block传入自己关联的queue中，执行block
    dispatch_resume(sourceReader);
    //-------------------------------------------------------------------------------------------------------------------
}


- (void)viewDidUnload
{
    [self setWebView1:nil];
    [self setWebView2:nil];
    [self setLabel:nil];
    [self setLabel1:nil];
    [self setView3:nil];
    [self setView4:nil];
    [self setProgress:nil];
    [self setLabel3:nil];
    [self setLabel4:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)buttonGCDPress:(id)sender
{
    dispatch_queue_t queue0 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    //用户事件------------------------------------------------------------------------------------------------------------
    __block int counter = 1;
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    
    //----------------------------
    //运行完成事件,执行后，data会清0
    //----------------------------
    dispatch_source_set_event_handler(source, ^{
        progress.progress = (float)counter++/4;
        NSLog(@"%ld",dispatch_source_get_data(source));
    });
    
    dispatch_resume(source);
    
    //-------------------------------------------------
    //利用for循环异步加入queue，完成后，调用主线程队列更新显示
    //-------------------------------------------------
    
//    for (int i = 0 ; i < 4; i++)
//    {
//        NSString *string = [arrayURL objectAtIndex:i];
//        dispatch_group_async(group, queue0, ^{
//            NSData *content = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:string]];
//            UIImage *image = [UIImage imageWithData:content];
//            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//            imageView.frame = CGRectMake(0, 0, 50, 75);
//            
//            dispatch_source_merge_data(source, 1);
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [(UIView *)[arrayContent objectAtIndex:i] addSubview:imageView];
//            });
//        });
//    }
    
    //--------------------------------------------------------------------------------------------------------------------
    
    //---------------------------------------------------------------------------------
    //dispatch_apply的用法,这个方法会同步的调用block多次，单我们可以异步的将这个方法加入一个queue
    //---------------------------------------------------------------------------------
    
    dispatch_async(queue0, ^{
        //同步分配，异步加入queue
        dispatch_apply(4, queue0, ^(size_t index){
            NSString *string = [arrayURL objectAtIndex:index];
            NSData *content = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:string]];
            UIImage *image = [UIImage imageWithData:content];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = CGRectMake(0, 0, 50, 75);
            
            //-------------------------------------------------------------------
            //触发用户事件，将1添加到source后，运行完成事件处理器（主线程中）
            //这时，如果主线程忙或者工作单元运行很快完成，那么，完成事件会进行合并
            //-------------------------------------------------------------------
            dispatch_source_merge_data(source, 1);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [(UIView *)[arrayContent objectAtIndex:index] addSubview:imageView];
            });
        });
    });
    //--------------------------------------------------------------------------------------------------------------------
    
    
    //---------------------------------------------------------
    //监测group中所有的block执行完后，向一个指定的queue发送一个block
    //---------------------------------------------------------
    __block BOOL flag = 0;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (dispatch_get_current_queue() == dispatch_get_main_queue())
        {
            flag = 1;
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[NSString alloc] initWithFormat:@"%d",flag] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    });
    dispatch_release(group);
    //-------------------------------------------------------------------------------------------------------------------
}
- (IBAction)button_applyPress:(id)sender
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //--------------------------------------------------------------------------------------------------
        //apply的作用是往queue中连续添加[arrayURL count]（自己定义）遍的block方法，并将从0开始的调用次数传给block的参数
        //--------------------------------------------------------------------------------------------------
        dispatch_apply([arrayURL count], queue, ^(size_t index){
            dispatch_async(dispatch_get_main_queue(), ^{
                UILabel *labelTest = [arrayLabel objectAtIndex:index];
                labelTest.text = [arrayURL objectAtIndex:index];
                NSLog(@"%@",labelTest.text);
            });
        });
    });
}

//------------------------------------------------------------------------------------------------------------------------
//自定义一个返回一个timer dispatch source的函数，用于创建timer dispatch source
//-----------------------------------------------------------------------

dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
};
//------------------------------------
//具体实例化一个timer dispatch source
//------------------------------------
- (IBAction)timerPresss:(id)sender
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //---------------------------------------------------------------------
    //这个block是在source相关联的那个queue中执行的，事件发生后，会异步传入这个queue中
    //---------------------------------------------------------------------
    dispatch_block_t block = ^{
        
            dispatch_apply([arrayLabel count], queue, ^(size_t index){
                
                NSString *string = [arrayURL objectAtIndex:index];
                NSData *content = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:string]];
                UIImage *image = [UIImage imageWithData:content];
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                imageView.frame = CGRectMake(0, 0, 50, 75);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIView *)[arrayContent objectAtIndex:index] addSubview:imageView];
                    progress.progress = (float)(index+1)/4;
                    NSLog(@"%ld",index);
                });
            });
    };
    CreateDispatchTimer(2*NSEC_PER_SEC, 60, queue, block);
}
//------------------------------------------------------------------------------------------------------------------------
@end
