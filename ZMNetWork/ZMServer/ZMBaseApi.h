//
//  ZMBaseApi.h
//  Business
//
//  Created by 杨飞宇 on 16/4/1.
//  Copyright © 2016年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMServerError.h"

@interface ZMBaseApi : NSObject

+ (ZMServerError *)checkResult:(NSString *)errorCode errorMsg:(NSString *)errorMsg;

@end
