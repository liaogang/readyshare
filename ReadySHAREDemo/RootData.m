//
//  RootData.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/12.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RootData.h"
#import "constStrings.h"




@interface RootData ()
@property (nonatomic,strong) NSMutableArray *items;


@property (nonatomic,strong) NSMutableArray *itemsMovie,*itemsMusic,*itemsPhoto,*itemsBook;
@end


@implementation RootData

-(void)reset
{
    _items = [NSMutableArray array];
    
    _error = nil;
    
    _itemsMovie = [NSMutableArray array];
    _itemsMusic = [NSMutableArray array];
    _itemsPhoto = [NSMutableArray array];
    _itemsBook = [NSMutableArray array];
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self reset];
        self.idReloadDate = 0;
        self.idLastReload = -1;
        self.playingIndex = -1;
    }
    
    return self;
}

+(instancetype)shared
{
    static RootData * r = nil;
    if (r == nil) {
        r = [[RootData alloc]init];
    }
    
    return r;
}

-(void)generateNewID
{
    self.idReloadDate++;
}

-(void)reload:(Finished)callback
{
    KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
    
    [provider fetchAtPath:_path block:^(id result) {
        
        [self ParseFetchResult:result];
        callback();
    }];
}


-(void)ParseFetchResult:(id)result
{
    [self reset];

    if ([result isKindOfClass:[NSError class]])
    {
        _error = result;
    }
    else
    {
        if ([result isKindOfClass:[NSArray class]])
        {
            NSArray *arr = (NSArray*)result;
            [_items addObjectsFromArray: arr];
            
        } else if ([result isKindOfClass:[KxSMBItem class]])
        {
            KxSMBItem *item = (KxSMBItem*)result;
            [_items addObject:item];
        }
    }
    
}

-(NSMutableArray*)getDataOfCurrMediaType
{
    switch (self.currMediaType)
    {
        case MediaTypeMovie:
            return _itemsMovie;
        case MediaTypeMusic:
            return _itemsMusic;
        case MediaTypePhoto:
            return _itemsPhoto;
        case MediaTypeBook:
            return _itemsBook;
    }
}


-(NSArray*)getDataOfCurrMediaTypeVerifyFiltered
{
    NSMutableArray *arr = [self getDataOfCurrMediaType];
   
    if (arr.count == 0)
    {
        for (id item in _items)
        {
            if ([item isKindOfClass:[KxSMBItemFile class]])
            {
                KxSMBItem *it = (KxSMBItem*)item;
                if(filterPathByMediaType(it.path, self.currMediaType) )
                    [arr addObject: it];
            }
        }
    }
    
    
    return arr;
}

-(NSString*)generateTempFolder
{
    return  generateTempFolderName();
}

-(NSString*)smbFileExistsAtCache:(KxSMBItemFile*)file :(BOOL*)exsit
{
    NSString *fileName = [@(file.stat.lastModified.timeIntervalSince1970).stringValue  stringByAppendingFormat:@"-%@",file.path.lastPathComponent];
    
    NSString *folder = [self generateTempFolder];
    
    NSString *result = [folder stringByAppendingPathComponent:fileName];
    
    *exsit = [[NSFileManager defaultManager] fileExistsAtPath:result isDirectory: 0];
    
    return result;
}

-(void)getSmbFileCached:(FinishedWithResult)callback
{
    
}

@end

BOOL filterPathByMediaType(NSString *path ,enum MediaType type)
{
    NSString *pathExtension = path.pathExtension.lowercaseString;
    
    if (type == MediaTypeMovie)
    {
        NSRange r = [kSupportedFileExtensions rangeOfString:pathExtension];
        
        return  r.location != NSNotFound;
    }
    else if ( type == MediaTypeMusic)
    {
       return  [arrayMusicTypes containsObject:pathExtension];
    }
    else if ( type == MediaTypePhoto)
    {
        return  [arrayPictureTypes containsObject:pathExtension];
    }
    else if ( type == MediaTypeBook)
    {
        return  [arrayBookTypes containsObject:pathExtension];
    }
    
    return NO;
}


NSString * generateTempFolderName()
{
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    
    
    folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
    
    [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:folder]
                             withIntermediateDirectories:YES attributes:nil error:nil ];
    
    return folder;
}

NSError* clearTempFolder()
{
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    
    
    folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
    
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:folder] error:&error];
    
    if (error)
    {
        NSLog(@"Remove folder error: %@",error);
    }
    else
    {
        NSLog(@"Folder removed: %@",folder);
    }
    
    return error;
}

