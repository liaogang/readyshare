//
//  PlayerTypeDefines.h
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//


#import <Foundation/Foundation.h>


typedef NS_ENUM(int, PlayOrder)
{
    playorder_default ,
    playorder_random ,
    playorder_repeat_single ,
    playorder_repeat_list ,
    playorder_shuffle,
    playorder_single
};


#define kPlayOrder (  @[ \
NSLocalizedString(@"default", nil),\
NSLocalizedString(@"random" ,nil),\
NSLocalizedString(@"repeat-single" ,nil),\
NSLocalizedString(@"repeat-list" ,nil),\
NSLocalizedString(@"shuffle",nil),\
NSLocalizedString(@"single",nil),\
])


enum PlayState
{
    playstate_stopped,
    playstate_playing,
    playstate_paused,
    playstate_pending
};


struct PlayStateTime
{
    enum PlayState state;
    NSTimeInterval time;
    CGFloat volume;
};



#define docFileName  @"core.cfg"
#define layoutFileName  @"ui.cfg"
#define keyblindingFileName @"keymaps.json"
#define playlistDirectoryName @"playlist"
#define playlistIndexFileName @"index.cfg"


enum PlayerListType
{
    type_normal,
    type_temporary
};


/** 
    Get target number index by given order at area [from,to).
    @return (to -1) if failed.
 */
int getNext(enum PlayOrder order , int curr, int from , int to);
