//
//  ZMResponse.h
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMResponse : NSObject

@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly) NSString *msg;
@property (nonatomic, copy, readonly) NSDictionary *data;

@end
