//
//  fileTypes.m
//  GenieiPad
//
//  Created by liaogang on 6/20/14.
//
//


#import "fileTypes.h"
#import <AVFoundation/AVFoundation.h>






NSData * getId3FromAudio2(NSURL *audioFile, NSMutableString *album, NSMutableString *artist,NSMutableString *title)
{
    NSData *result;
    if (!audioFile) {
        return nil;
    }
    
    AVURLAsset *mp3Asset = [[AVURLAsset alloc] initWithURL:audioFile options:nil];
    
    if (!mp3Asset) {
        return nil;
    }
    
    const int thingsNeedFind = 4;
    BOOL n = 0;
    
    for (NSString *format in [mp3Asset availableMetadataFormats])
    {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format])
        {
            NSString *commonKey = metadataItem.commonKey;
            
            if ([commonKey isEqualToString:AVMetadataCommonKeyArtwork])
            {
                
                if ([metadataItem.value isKindOfClass:[NSDictionary class]]) {
                    result = [(NSDictionary*)metadataItem.value objectForKey:@"data"];
                }
                else if([metadataItem.value isKindOfClass:[NSData class] ])
                {
                    result = (NSData*)metadataItem.value;
                }
                
                n++;
            }
            else if ([commonKey isEqualToString:AVMetadataCommonKeyAlbumName])
            {
                [album setString:metadataItem.stringValue];
                n++;
            }
            else if ([commonKey isEqualToString:AVMetadataCommonKeyTitle])
            {
                [title setString:metadataItem.stringValue];
                n++;
            }
            else if( [commonKey isEqualToString:AVMetadataCommonKeyArtist])
            {
                [artist setString:metadataItem.stringValue];
                n++;
            }
            
            if (n==thingsNeedFind)
                break;
            
        }
        
        if (n==thingsNeedFind)
            break;
    }
    
    //if no title find , use the file name.
    if ([title isEqualToString:@""]) {
        [title setString: audioFile.path.lastPathComponent.stringByDeletingPathExtension];
    }
    
    return result;
}

UIImage * getId3FromAudio(NSURL *audioFile, NSMutableString *album, NSMutableString *artist,NSMutableString *title)
{
    return  [UIImage imageWithData:getId3FromAudio2(audioFile, album, artist, title)];
}




