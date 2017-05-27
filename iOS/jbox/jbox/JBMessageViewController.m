//
//  JBMessageViewController.m
//  极光宝盒
//
//  Created by wuxingchen on 16/7/20.
//  Copyright © 2016年 57380422@qq.com. All rights reserved.
//

#import "JBMessageViewController.h"
#import "JBMessageTableViewCell.h"
#import "JBMessage.h"
#import "JBDatabase.h"
#import "JPUSHService.h"
#import "JBNetwork.h"
#import <MJRefresh.h>

@interface JBMessageViewController ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic ,retain)NSArray *messageArray;
@property(nonatomic, assign)BOOL appeared;
@property (weak, nonatomic) IBOutlet UILabel *placeholder_label;
@property(nonatomic, assign)int counts;
@end

@implementation JBMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.channel.name ? self.channel.name : @"频道";
    self.counts = 20;
    self.message_tableView.tableFooterView = [UIView new];

    //bar
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"message_btn"] style:UIBarButtonItemStylePlain target:self action:@selector(slide:)];

    //data
    if ([JBDatabase getSortedDevkeyAndChannel].count) {
        self.channel = ((NSArray*)([(NSDictionary*)([JBDatabase getSortedDevkeyAndChannel][0]) allValues][0])).firstObject;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:kJPFNetworkDidReceiveMessageNotification object:nil];

    [self updateData];

    WEAK_SELF(weakSelf);
    self.message_tableView.mj_footer = [MJRefreshBackStateFooter footerWithRefreshingBlock:^{
        [weakSelf.message_tableView.mj_footer endRefreshing];
        weakSelf.counts = weakSelf.counts + 20;
        [weakSelf updateData];
    }];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(slide:)];
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(slide:)];
    [self.view addGestureRecognizer:tap];
    [self.view addGestureRecognizer:swipe];
    tap.delegate = self;

    self.scrollViewController = [[JBScrollViewController alloc] initWithNibName:@"JBScrollViewController" bundle:nil];
    [[[UIApplication sharedApplication] keyWindow] addSubview:_scrollViewController.view];

}

-(void)didReceiveMessage:(NSNotification*)noti{
    NSDictionary *dict = [noti userInfo];
    JBMessage *message = [JBMessage new];
    message.title      = dict[@"title"];
    message.content    = dict[@"content"];
    message.devkey     = dict[@"extras"][@"dev_key"];
    message.channel    = dict[@"extras"][@"channel"];
    message.time       = dict[@"extras"][@"datetime"];
    message.icon       = dict[@"extras"][@"icon"];
    message.read       = @"0";
    message.url        = dict[@"extras"][@"url"];
    message.integration_name = dict[@"extras"][@"integration_name"];
    [JBDatabase insertMessages:@[message]];
    [self.message_tableView reloadData];
    [self updateData];
}

-(void)slide:(UIGestureRecognizer*)gesture{
    if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer *swipe = (UISwipeGestureRecognizer*)gesture;
        if (swipe.direction == UISwipeGestureRecognizerDirectionLeft && self.isSlideOut) {
            [self slideAnimate];
        }
    }else if(self.isSlideOut){
        [self slideAnimate];
    }else if([gesture isKindOfClass:[UIBarButtonItem class]]){
        [self slideAnimate];
    }
}

-(void)slideAnimate{
    WEAK_SELF(weakSelf);
    if (self.isSlideOut) {
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.scrollViewController.view.frame = CGRectMake(- SlideViewWidth, 0, SlideViewWidth, UIScreenHeight);
            weakSelf.navigationController.view.frame = CGRectMake(0, 0, UIScreenWidth, UIScreenHeight);
            weakSelf.isSlideOut              = NO;
        }];
    }else{
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.scrollViewController.view.frame = CGRectMake(0, 0, SlideViewWidth, UIScreenHeight);
            weakSelf.navigationController.view.frame = CGRectMake(SlideViewWidth, 0, UIScreenWidth, UIScreenHeight);
            weakSelf.isSlideOut              = YES;
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [JBDatabase setAllMessagesReadWithChannel:self.channel];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.appeared = YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.appeared = NO;
}

-(void)setChannel:(JBChannel *)channel{
    _channel = channel;
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateData) userInfo:nil repeats:NO];
    self.title = channel.name;
}

-(void)updateData{
    NSMutableArray *mArray1 = [JBDatabase getMessagesFromChannel:_channel];
    NSArray *mArray2        = [[mArray1 reverseObjectEnumerator] allObjects];
    NSRange range = NSMakeRange(0, self.counts);
    if (mArray2) {
        if (mArray2.count >= self.counts) {
            self.messageArray = [mArray2 subarrayWithRange:range];
        }else{
            self.messageArray = mArray2;
        }
    }

    [self.message_tableView reloadData];
//    if (self.messageArray.count > 0) {
//        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageArray.count - 1 inSection:0];
//        [self.message_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        [self.view layoutIfNeeded];
//    }
    if (self.appeared && !self.isSlideOut) {
        [JBDatabase setAllMessagesReadWithChannel:self.channel];
    }
}

-(void)setIsSlideOut:(BOOL)isSlideOut{
    _isSlideOut = isSlideOut;
    if (!isSlideOut) {
        [JBDatabase setAllMessagesReadWithChannel:self.channel];
    }
}

-(NSArray *)messageArray{
    if (!_messageArray) {
        _messageArray = [NSArray array];
    }
    return _messageArray;
}

#pragma mark - tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    JBMessageTableViewCell *cell = (JBMessageTableViewCell*)[self tableView:_message_tableView cellForRowAtIndexPath:indexPath];
    if (!cell) {
        return 60;
    }
    return cell.suitableHeight;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    JBMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellReuseIdentifier];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"JBMessageTableViewCell" owner:nil options:nil].lastObject;
    }
    cell.message = self.messageArray[indexPath.row];
    cell.userInteractionEnabled = YES;

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    JBMessageTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.message.url && ![cell.message.url isEqualToString:@""]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cell.message.url]];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return self.isSlideOut;
    }
    return YES;
}

@end
