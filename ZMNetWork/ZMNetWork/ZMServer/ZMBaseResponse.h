//
//  ZMBaseResponse.h
//  Business
//
//  Created by 杨飞宇 on 15/10/19.
//  Copyright © 2015年 zhimadj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMBaseResponse : NSObject

@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly) NSString *msg;
@property (nonatomic, copy, readonly) id data;

@end
