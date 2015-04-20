//
//  RootData.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//


typedef void (^reloadFinished)();


enum MediaType
{
    MediaTypeMovie,
    MediaTypeMusic,
    MediaTypePhoto,
    MediaTypeBook,
};



@interface RootData : NSObject
+(instancetype)shared;

@property (nonatomic,strong) NSString * path;
@property (nonatomic,strong) NSString *userName,*passWord,*group;

@property (nonatomic) enum MediaType currMediaType;

/// check error first. and then getDataOfCurrMediaTypeVerifyFiltered
-(void)reload:(reloadFinished)callback;

@property (nonatomic,strong) NSError *error;

-(NSArray*)getDataOfCurrMediaTypeVerifyFiltered;

@end


BOOL filterPathByMediaType(NSString *path ,enum MediaType type);


