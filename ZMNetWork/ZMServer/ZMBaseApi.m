//
//  ZMBaseApi.m
//  Business
//
//  Created by 杨飞宇 on 16/4/1.
//  Copyright © 2016年 zhimadj. All rights reserved.
//

#import "ZMBaseApi.h"
#import "ZMServerAPIConst.h"
#import "GeTuiSdk.h"
#import "ZMNotificationConst.h"
#import "ZMLoginViewController.h"

@implementation ZMBaseApi

+ (ZMServerError *)checkResult:(NSString *)errorCode errorMsg:(NSString *)errorMsg {
    if (![errorCode isEqualToString:ZMCodeSuccess]) {
        if ([errorCode isEqualToString:ZMCodeAuthFailed]) { //授权失败，需要重新登录
            NSString *store_id = [ZMUserDAO currentStoreId];
            DDLogDebug(@"解绑之前打印clientId:%@---storeId:%@",[GeTuiSdk clientId],store_id);
            [GeTuiSdk unbindAlias:[NSString stringWithFormat:@"%@",store_id]];
            
            NSNotification *notification = [NSNotification notificationWithName:kNotificationLogoutSuccess object:nil userInfo:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            [UIApplication sharedApplication].keyWindow.rootViewController = [[ZMLoginViewController alloc] init];
        }
        
        ZMServerError *error = [ZMServerError errorWithCode:errorCode msg:errorMsg];
        return error;
    }
    
    return nil;
}

@end
