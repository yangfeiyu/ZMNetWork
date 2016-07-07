//
//  ZMBaseServerError.h
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMBaseServerError : NSError

@property (strong, nonatomic, readonly) NSString *serverCode;
@property (strong, nonatomic, readonly) NSString *serverMsg;
@property (strong, nonatomic, readonly) NSString *serverTips;

+ (instancetype)errorWithCode:(NSString *)serverCode msg:(NSString *)serverMsg;
+ (instancetype)errorWithCode:(NSString *)serverCode msg:(NSString *)serverMsg userInfo:(NSDictionary *)dict;
@end
