//
//  RootData.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//
#import "KxSMBProvider.h"

typedef void (^Finished)();
typedef void (^FinishedWithResult)(id result);


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
-(void)reload:(Finished)callback;

/// will refresh at every each reload.
@property (nonatomic) int idReloadDate,idLastReload;
@property (nonatomic,strong) NSError *error;

-(NSArray*)getDataOfCurrMediaTypeVerifyFiltered;


-(NSString*)generateTempFolder;

/** Test if a temp file is exsited and cached in temp folder.
 @return file's full path.
*/
-(NSString*)smbFileExistsAtCache:(KxSMBItemFile*)file :(BOOL*)exsit;

-(void)getSmbFileCached:(FinishedWithResult)callback;

@property (nonatomic) int playingIndex;
@property (nonatomic,strong) NSString *playingFilePath;
@end


BOOL filterPathByMediaType(NSString *path ,enum MediaType type);


NSString * generateTempFolderName();

NSError* clearTempFolder();
