//
//  RootData.h
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//
#import "KxSMBProvider.h"
#import "PlayerTrack.h"
#import "PlayerTypeDefines.h"

typedef void (^Finished)();
typedef void (^FinishedWithResult)(id result);


enum MediaType
{
    MediaTypeMovie = 1000,
    MediaTypeMusic,
    MediaTypePhoto,
    MediaTypeBook,
    MediaTypeInternet,
    MediaTypeFileBrowse,
};



@interface RootData : NSObject
+(instancetype)shared;

-(void)setPathAndLoadAuthInfo:(NSString*)path;

@property (nonatomic,strong) NSString * path;
@property (nonatomic,strong) NSString *userName,*passWord,*group;

@property (nonatomic) enum MediaType currMediaType;

/// check error first. and then getDataOfCurrMediaTypeVerifyFiltered
-(void)reload:(FinishedWithResult)callback;
-(void)ParseFetchResult:(id)result;

/// will refresh at every each reload.
@property (nonatomic) int idReloadDate,idLastReload;
@property (nonatomic,strong) NSError *error;

-(NSArray*)getDataOfCurrMediaTypeVerifyFiltered;


-(NSString*)generateTempFolder;

/** Test if a temp file is exsited and cached in temp folder.
 @return file's full path.
*/
-(NSString*)smbFileExistsAtCache:(KxSMBItemFile*)file :(BOOL*)exsit;

-(void)getSmbFileCached:(KxSMBItemFile*)file callback:(FinishedWithResult)callback;


/// music module ==> playing stuffs.
@property (nonatomic) int playingIndex;
@property (nonatomic,strong) NSString *playingFilePath;
@property (nonatomic,strong) TrackInfo *playingTrack;
@property (nonatomic) enum PlayOrder order;
-(void)playItemAtIndex:(int)index;
-(void)playNext;
-(void)playPrev;
@end


#if defined(__cplusplus)
extern "C" {
#endif /* defined(__cplusplus) */
BOOL filterPathByMediaType(NSString *path ,enum MediaType type);


NSString * generateTempFolderName();

NSError* clearTempFolder();

#if defined(__cplusplus)
}
#endif /* defined(__cplusplus) */
