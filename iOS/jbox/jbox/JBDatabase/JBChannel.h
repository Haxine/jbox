//
//  JBChannel.h
//  极光宝盒
//
//  Created by wuxingchen on 16/8/12.
//  Copyright © 2016年 57380422@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBChannel : NSObject
@property(nonatomic, retain)NSString *dev_key;
@property(nonatomic, retain)NSString *name;//channel 字段
@property(nonatomic, retain)NSString *isSubscribed;// 0/1
@end
