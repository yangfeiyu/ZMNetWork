//
//  ZMBaseRequestParam.m
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import "ZMBaseRequestParam.h"
#import "Guid.h"
#import "FCUUID.h"

@interface ZMBaseRequestParam ()

@property (nonatomic, strong) NSNumber *from;
@property (nonatomic, strong) NSNumber *sc_scale;
@property (nonatomic, copy) NSString *device_id;
@property (nonatomic, copy) NSString *os_vername;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *ppi;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *net;
@property (nonatomic, copy) NSString *operator;
@property (nonatomic, copy) NSString *request_id;

@end

@implementation ZMBaseRequestParam

- (instancetype)init {
    self = [super init];
    if (self) {
        self.device_id = [FCUUID uuidForDevice];
        self.from = @3;
        self.os_vername = [[UIDevice currentDevice] systemVersion];
        self.model = [UIDevice currentDevice].model;
        self.ppi = [NSString stringWithFormat:@"%.0fX%.0f", [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height];
        self.sc_scale = @([UIScreen mainScreen].scale);
        self.channel = @"AppStore";
        self.request_id = [[Guid randomGuid] stringValue];
    }
    return self;
}

@end
