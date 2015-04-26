//
//  AppDelegate.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/2.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "AppDelegate.h"
#import "PlayerMessage.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "RootData.h"
#import "PlayerEngine.h"
#import "PlayerMessage.h"

#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    initPlayerMessage();

    
    
    
    MainViewController *mainVC =[[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    
    
    
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController: mainVC];

    nav.navigationBar.translucent = false;
    
    self.window = [[UIWindow alloc]initWithFrame: [[UIScreen mainScreen] bounds]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    
    
    
    

    addObserverForEvent(self , @selector(trackStarted:), EventID_track_started);
    
    
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    
    // Clear the cache file if it's too much.
    // clearTempFolder();
    
    return YES;
}


-(void)trackStarted:(NSNotification*)n
{
    ProgressInfo *info = n.object;
    [self setPlayInfoWhenBeingBackground:info];
}

//add by zemeng
- (void) setPlayInfoWhenBeingBackground:(ProgressInfo*)pgInfo
{
    RootData *s = [RootData shared];
    TrackInfo *track = s.playingTrack;
    
    
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = track.title;  //歌曲名字
    info[MPMediaItemPropertyArtist] = track.artist; //歌手
    info[MPMediaItemPropertyAlbumTitle] = track.album; //唱片名字
    info[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    
    if (track.image) {
        info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:track.image];
    }
    
    info[MPMediaItemPropertyPlaybackDuration] = @(pgInfo.total).stringValue;
    
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(pgInfo.current).stringValue;
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case  UIEventSubtypeRemoteControlPlay:
                postEvent(EventID_to_play_pause_resume, nil);
                break;
            case UIEventSubtypeRemoteControlPause:
                postEvent(EventID_to_play_pause_resume, nil);
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                postEvent(EventID_to_play_next, nil);
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            default:
                break;
        }
    }
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
