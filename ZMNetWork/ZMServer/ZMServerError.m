//
//  ZMServerError.m
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import "ZMServerError.h"
#import "ZMServerAPIConst.h"
#import "ZMNotificationConst.h"

static NSString *const kServerAPIErrorDomain = @"ServerAPIError";
static const NSInteger kServerAPIErrorCode = 9999;

@interface ZMServerError ()

@property (strong, nonatomic) NSString *serverCode;
@property (strong, nonatomic) NSString *serverMsg;
@property (strong, nonatomic) NSString *serverTips;

@end

@implementation ZMServerError

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
    
    ZMServerError *error = [[ZMServerError alloc] initWithDomain:kServerAPIErrorDomain code:kServerAPIErrorCode userInfo:[mutableDict copy]];
    [error fireNotification];
    DDLogError(@"server api error occur: %@", error);
    return error;
}

- (void)fireNotification {
    NSNotification *notification = [NSNotification notificationWithName:kNotificationServerAPIError object:nil userInfo:@{@"error": self}];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (NSString *)serverMsg {
    return self.userInfo[@"serverMsg"];
}

- (NSString *)serverCode {
    return self.userInfo[@"serverCode"];
}

- (NSString *)serverTips {
    NSString *code = self.serverCode;
    if (code.length == 0) {
        code = @"未知错误";
    }
    
//    NSString *errorTips = HOECodeDescDict[self.serverCode];
//    if (errorTips.length == 0) {
//        errorTips = @"网络请求失败";
//    }
    
    NSString *errorTips;
    if (self.serverMsg.length > 0 ) {
        errorTips = self.serverMsg;
    } else {
        errorTips = @"数据请求失败";
    }
    
    return errorTips;
}

@end
