//
//  ZMBaseServerError.m
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import "ZMBaseServerError.h"

static NSString *const kServerAPIErrorDomain = @"ServerAPIError";
static const NSInteger kServerAPIErrorCode = 9999;

@interface ZMBaseServerError ()

@property (strong, nonatomic) NSString *serverCode;
@property (strong, nonatomic) NSString *serverMsg;
@property (strong, nonatomic) NSString *serverTips;

@end

@implementation ZMBaseServerError

+ (instancetype)errorWithCode:(NSString *)serverCode msg:(NSString *)serverMsg {
    return [self errorWithCode:serverCode msg:serverMsg userInfo:nil];
}

// serverCode should not be null, otherwise the app will be crashed
+ (instancetype)errorWithCode:(NSString *)serverCode msg:(NSString *)serverMsg userInfo:(NSDictionary *)dict {
    NSMutableDictionary *mutableDict;
    if (dict) {
        mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    } else {
        mutableDict = [[NSMutableDictionary alloc] init];
    }
    if (serverCode) {
        mutableDict[@"serverCode"] = serverCode;
    }
    
    if (serverMsg) {
        mutableDict[@"serverMsg"] = serverMsg;
    }
    
    ZMBaseServerError *error = [[ZMBaseServerError alloc] initWithDomain:kServerAPIErrorDomain code:kServerAPIErrorCode userInfo:[mutableDict copy]];
    return error;
}

- (NSString *)serverMsg {
    return self.userInfo[@"serverMsg"];
}

- (NSString *)serverCode {
    return self.userInfo[@"serverCode"];
}

- (NSString *)serverTips {
    NSString *errorTips;
    if (self.serverMsg.length > 0 ) {
        errorTips = self.serverMsg;
    } else {
        errorTips = @"数据请求失败";
    }
    
    return errorTips;
}

@end
