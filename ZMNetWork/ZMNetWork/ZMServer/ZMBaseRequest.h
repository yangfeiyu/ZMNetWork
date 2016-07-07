//
//  ZMBaseRequest.h
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTKRequest.h"

@interface ZMBaseRequest : YTKRequest

- (instancetype)initWithUrl:(NSString *)reqUrl method:(YTKRequestMethod)reqMethod arguments:(NSDictionary *)reqArguments;

@end
