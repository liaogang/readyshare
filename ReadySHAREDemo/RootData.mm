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
#import "PlayerEngine.h"
#import "PlayerMessage.h"
#import "UIAlertViewBlock.h"
#import "fileTypes.h"

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
        self.order = playorder_default;
        
        addObserverForEvent(self, @selector(playNext), EventID_track_stopped_playnext);
        addObserverForEvent(self, @selector(playNext), EventID_to_play_next);
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




-(void)playItemAtIndex:(int)index
{
    RootData *r = self;

    
    NSArray *arr = [r getDataOfCurrMediaTypeVerifyFiltered];
    
    KxSMBItemFile *file = arr[index];
    
    BOOL exsit = false;
    
    NSString *fullFileName = [[RootData shared] smbFileExistsAtCache:file :&exsit];
    r.playingFilePath = fullFileName;
    
    if (exsit)
    {
        // Verify the file size is OK.
        NSError *error;
        NSDictionary* dicAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullFileName error:&error];
        
        if (error)
        {
            NSLog(@"error: %@",error);
            exsit = false;
        }
        else
        {
            unsigned long long size = [dicAttributes fileSize];
            
            if ( size == file.stat.size)
            {
                // Verify OK , play.
                r.playingIndex = index;
                //r.playingTrack =
                
                [self playFileAtPath: fullFileName];
                
//                [engine playURL: [NSURL fileURLWithPath:fullFileName]];
            }
            else
            {
                exsit = false;
            }
        }
    }
    
    if (!exsit)
    {
        [file readDataToEndOfFile:^(id result)
         {
             if ([result isKindOfClass:[NSData class]])
             {
                 NSData *data = result;
                 [data writeToFile:fullFileName atomically:YES];
                 
                 
                 [RootData shared].playingIndex = index;

             }
             else if([result isKindOfClass:[NSError class]])
             {
                 NSError *error = result;
                 NSLog(@"download smb file error: %@",error);
                 
                 [[[UIAlertViewBlock alloc]initWithTitle:NSLocalizedString(@"Error downloading smb file", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             }
         }];
    }
}

-(void)playFileAtPath:(NSString*)path
{
    
    NSMutableString *album = [ NSMutableString string];
    NSMutableString *artist = [ NSMutableString string];
    NSMutableString *title = [ NSMutableString string];
    NSMutableString *lyrics = [ NSMutableString string];
    
    
    UIImage *image = getId3FromAudio( [NSURL fileURLWithPath: path ] , album, artist, title , lyrics);
    
    
    self.playingTrack = [[TrackInfo alloc]init];
    _playingTrack.title = title;
    _playingTrack.artist = artist;
    _playingTrack.album = album;
    _playingTrack.lyrics = lyrics;
    _playingTrack.image = image;
    
    
    PlayerEngine *engine = [PlayerEngine shared];
    [engine playURL: [NSURL fileURLWithPath:path]];
    
}

-(void)playNext
{
    int next = getNext(_order,  _playingIndex, 0, [self getDataOfCurrMediaTypeVerifyFiltered].count );
    
    if (next != -1)
    {
        [[RootData shared] playItemAtIndex: next ];
    }
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

