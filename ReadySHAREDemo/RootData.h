//
//  RootData.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//


@interface RootData : NSObject
+(instancetype)shared;

@property (nonatomic,strong) NSString * path;
@property (nonatomic,strong) NSString *userName,*passWord,*group;

@end


enum MediaType
{
    MediaTypeMovie,
    MediaTypeMusic,
    MediaTypePhoto,
    MediaTypeBook
};

BOOL fliterPathByMediaType(NSString *path ,enum MediaType type);


