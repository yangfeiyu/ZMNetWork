//
//  ZMRequest.m
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import "ZMRequest.h"
#import "ZMRequestParam.h"

@interface ZMRequest ()

@property (nonatomic, strong) NSString *reqUrl;
@property (nonatomic, assign) YTKRequestMethod reqMethod;
@property (nonatomic, strong) NSDictionary *reqArguments;

@end

@implementation ZMRequest

- (instancetype)initWithUrl:(NSString *)reqUrl method:(YTKRequestMethod)reqMethod arguments:(NSDictionary *)reqArguments {
    self = [super init];
    if (self) {
        self.reqUrl = reqUrl;
        self.reqMethod = reqMethod;
        self.reqArguments = reqArguments;
    }
    return self;
}

/**
 *  请求url
 */
- (NSString *)requestUrl {
    if (self.reqUrl) {
        return self.reqUrl;
    }
    return @"";
}

/**
 *  请求方法
 */
- (YTKRequestMethod)requestMethod {
    return self.reqMethod;
}

/**
 *  请求参数
 */
- (id)requestArgument {
    if (!self.reqArguments) {
        ZMRequestParam *param = [[ZMRequestParam alloc] init];
        return param.mj_keyValues;
    }
    return self.reqArguments;
}

///**
// *  验证请求返回结果的类型
// */
//- (id)jsonValidator {
//    return @[@{
//                 @"id": [NSNumber class],
//                 @"imageId": [NSString class],
//                 @"time": [NSNumber class],
//                 @"status": [NSNumber class],
//                 @"question": @{
//                         @"id": [NSNumber class],
//                         @"content": [NSString class],
//                         @"contentType": [NSNumber class]
//                         }
//                 }];
//}

/**
 *  缓存时间
 */
- (NSInteger)cacheTimeInSeconds {
    return 0;
}

@end
