//
//  ZMBaseApi.h
//  Business
//
//  Created by 杨飞宇 on 16/4/1.
//  Copyright © 2016年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMBaseServerError.h"

@interface ZMBaseApi : NSObject

/**
 *  子类重写此方法实现错误码检查
 */
+ (ZMBaseServerError *)checkResult:(NSString *)errorCode errorMsg:(NSString *)errorMsg;

@end
