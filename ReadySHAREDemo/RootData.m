//
//  RootData.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RootData.h"

@implementation RootData

+(instancetype)shared
{
    static RootData * r = nil;
    if (r == nil) {
        r = [[RootData alloc]init];
    }
    
    return r;
}

@end

BOOL fliterPathByMediaType(NSString *path ,enum MediaType type)
{
    if (path) {
        
        
        return YES;
    }
    
    return NO;
}

