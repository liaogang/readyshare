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
#import "KxSMBProvider.h"




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

-(void)reload:(reloadFinished)callback
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
    if (self.idLastReload >= 0)
        clearTempFolderByID(self.idLastReload);
    
    return  generateTempFolderNameByID(self.idReloadDate);
}

-(NSString*)tempFileExsit:(NSString*)fileName :(BOOL*)exsit
{
    NSString *folder = [self generateTempFolder];
    
    NSString *result = [folder stringByAppendingPathComponent:fileName];
    
    *exsit = [[NSFileManager defaultManager] fileExistsAtPath:result isDirectory: 0];
    
    return result;
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


NSString * generateTempFolderNameByID(int _id)
{
    static NSString *lastFolderName = nil;
    static int lastID = -1;
    
    if (_id == lastID )
    {
        return lastFolderName;
    }
    else
    {
        NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                NSUserDomainMask,
                                                                YES) lastObject];
        
        
        folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
        folder = [folder stringByAppendingPathComponent:@(_id).stringValue];
        
        [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:folder]
                                 withIntermediateDirectories:YES attributes:nil error:nil ];
        
        lastID = _id;
        lastFolderName = folder;
        
        return folder;
    }
}

NSError* clearTempFolderByID(int _id)
{
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    
    
    folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
    folder = [folder stringByAppendingPathComponent:@(_id).stringValue];
    
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:folder] error:&error];
    
    if (error) {
        NSLog(@"%@",error);
    }
    
    return error;
}

