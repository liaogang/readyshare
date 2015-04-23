//
//  fileTypes.h
//  GenieiPad
//
//  Created by liaogang on 6/20/14.
//
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>




/**
 *  get audio file's id3 info.
 *  @param audioFile: input
 *  @param album,artist,title: output info
 *  @return audio's album image.(封面图)
 */
UIImage * getId3FromAudio(NSURL *audioFile, NSMutableString *album, NSMutableString *artist,NSMutableString *title,NSMutableString *lyrics);

NSData * getId3FromAudio2(NSURL *audioFile, NSMutableString *album, NSMutableString *artist,NSMutableString *title,NSMutableString *lyrics);






