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

/// will refresh at every each reload.
@property (nonatomic) int idReloadDate,idLastReload;
@property (nonatomic,strong) NSError *error;

-(NSArray*)getDataOfCurrMediaTypeVerifyFiltered;


-(NSString*)generateTempFolder;

/** test a temp file is exsit in temp folder.
 @return file's full path.
*/
-(NSString*)tempFileExsit:(NSString*)fileName :(BOOL*)exsit;

@end


BOOL filterPathByMediaType(NSString *path ,enum MediaType type);

NSString * generateTempFolderNameByID(int _id);

NSError* clearTempFolderByID(int _id);

