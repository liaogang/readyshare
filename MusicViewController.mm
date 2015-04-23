//
//  MusicViewController.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/19.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "MusicViewController.h"
#import "RootData.h"
#import "musicTableViewCell.h"
#import "KxSMBProvider.h"

#import "PlayerTypeDefines.h"
#import "PlayerEngine.h"
#import "PlayerMessage.h"

#import "UIAlertViewBlock.h"

#import "fileTypes.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

void pauseLayer(CALayer * layer)
{
    if (layer.speed > 0.0)
    {
        CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
}

void resumeLayer(CALayer* layer)
{
    if (layer.speed == 0.0)
    {
        CFTimeInterval pausedTime = [layer timeOffset];
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        layer.beginTime = timeSincePause;
    }
}


UIImage * maskImage(UIImage *image ,UIImage *maskImage )
{
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef maskedImageRef = CGImageCreateWithMask([image CGImage], mask);
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef];
    
    CGImageRelease(mask);
    CGImageRelease(maskedImageRef);
    
    // returns new image with mask applied
    return maskedImage;
}


void valueToMinSec(double d, int *m , int *s)
{
    *m = d / 60;
    *s = (int)d % 60;
}


#pragma mark - UISlider (hideThumbWhenDisable)
@interface UISlider (hideThumbWhenDisable)
-(void)setSliderEnabled:(BOOL)e;
@end

@implementation UISlider (hideThumbWhenDisable)
-(void)setSliderEnabled:(BOOL)e
{
    self.enabled=e;
    if (e == FALSE)
    {
        [self setThumbImage:[UIImage imageNamed:@"clear_thumb"] forState:UIControlStateNormal];
    }
    else
    {
        [self setThumbImage:[UIImage imageNamed:@"seek_thumb"] forState:UIControlStateNormal];
    }
}

@end


@interface MusicViewController ()
<UITableViewDataSource,UITableViewDelegate>


@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbum;
@property (weak, nonatomic) IBOutlet UIImageView *imageAlbumItem;
@property (nonatomic,strong) UIImageView *albumImage,*placeHolder;

@property (weak, nonatomic) IBOutlet UIButton *btnOrder;
@property (weak, nonatomic) IBOutlet UIButton *btnSingle;
@property (weak, nonatomic) IBOutlet UIButton *btnRandom;

@property (weak, nonatomic) IBOutlet UISlider *sliderVolumn;

@property (weak, nonatomic) IBOutlet UILabel *labelLeft;

@property (weak, nonatomic) IBOutlet UISlider *sliderProgress;

@property (weak, nonatomic) IBOutlet UILabel *labelRight;


@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (weak, nonatomic) IBOutlet UIButton *btnPrev;

@property (weak, nonatomic) IBOutlet UIButton *btnPause;

@property (weak, nonatomic) IBOutlet UIButton *btnPlay;

@property (weak, nonatomic) IBOutlet UIButton *btnNext;


//add  by  zemeng
@property (nonatomic , retain)NSString * NameOfSonger;
@property (nonatomic, retain) NSString * musicAlbumName;
@property (nonatomic, retain) UIImage  * albumImageForBackground;


@property (nonatomic) enum PlayOrder order;
@property (nonatomic,strong) PlayerEngine *engine;

@end

@implementation MusicViewController

-(void)dealloc
{
    removeObserver(self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a place holder view.
    
    CGFloat width2 = self.imageAlbum.bounds.size.width / 2.;
    

    
    {
        CGFloat radius = 144.;
        
        self.placeHolder = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, radius, radius)];
        _placeHolder.layer.cornerRadius = radius / 2.;
        _placeHolder.layer.masksToBounds = YES;
        _placeHolder.autoresizingMask =  ~0;
        [self.imageAlbum addSubview: _placeHolder];
        _placeHolder.center=CGPointMake(width2, width2);
        _placeHolder.hidden = true;
    }
    

    
    self.imageAlbumItem.layer.cornerRadius = width2 - 152.;
    self.imageAlbumItem.layer.masksToBounds = YES;
   
    
    // imageAlbum
    
    self.imageAlbum.layer.cornerRadius = width2;
    self.imageAlbum.layer.masksToBounds = YES;
    

    
    // tableView
    self.tableView.backgroundColor=[UIColor clearColor];
    self.tableView.rowHeight = 42;
    self.tableView.layer.cornerRadius = 8;
    self.tableView.layer.masksToBounds = YES;
    
    
    
    
    self.order = playorder_default;
    
    self.engine = [PlayerEngine shared];
    
    
    
    [self.sliderVolumn setThumbImage:[UIImage imageNamed:@"seek_thumb"] forState:UIControlStateNormal];
    [self.sliderProgress setThumbImage:[UIImage imageNamed:@"seek_thumb"] forState:UIControlStateNormal];
    
    self.sliderVolumn.value = self.engine.volume;
 
    
    addObserverForEvent(self, @selector(playNext), EventID_track_stopped_playnext);
    addObserverForEvent(self , @selector(trackStarted:), EventID_track_started);
    addObserverForEvent(self , @selector(updateUI), EventID_track_state_changed);
    addObserverForEvent(self, @selector(updateProgressInfo:), EventID_track_progress_changed);
    addObserverForEvent(self, @selector(playNext), EventID_to_play_next);

    
    RootData *r = [RootData shared];
    [r reload:^{
        
        if (r.error)
        {
            
        }
        else
        {
            [self.tableView reloadData];
        }
    }];
    
    
    if ([self.engine isPlaying]) {
        [self.sliderProgress setMaximumValue: self.engine.totalTime];
        [self.sliderProgress setValue: 0];
        [self setTitleAndAlbumImage];
    }
    
    [self updateUI];
    
    
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case  UIEventSubtypeRemoteControlPlay:
                
                [self actionPlay:nil];
                break;
            case UIEventSubtypeRemoteControlPause:
                
                [self actionPause:nil];
                break;

            case UIEventSubtypeRemoteControlNextTrack:
                [self actionNext:nil];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self actionPrev:nil];
                break;
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *cellIdentifier = @"musicTableCell";
    
    musicTableViewCell *cell ;//= [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell)
        cell = [[musicTableViewCell alloc]initWithNib];
    
    NSArray *arr = [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered];

    KxSMBItemFile *file = arr[indexPath.row];
    
    cell.textNumber.text = @(indexPath.row + 1).stringValue;
    
    cell.textName.text = file.path.lastPathComponent;
    
//    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
//    
//    backView.backgroundColor = [UIColor clearColor];
//    
//    cell.backgroundView = backView;
    
    return cell;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
      [cell setBackgroundColor:[UIColor clearColor]];
}


#pragma mark - Custom view for table header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 48;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view= [[NSBundle mainBundle]loadNibNamed:@"musicTableHeader" owner:self options:nil][0];
    return view;
}

#pragma mark - delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self playItemAtIndex:indexPath.row];
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    
    RootData *r= [RootData shared];
    NSArray *arr = [r getDataOfCurrMediaTypeVerifyFiltered];
    
    KxSMBItemFile *file = arr[index];
    
    BOOL exsit = false;
    
    [[RootData shared] smbFileExistsAtCache:file :&exsit];
    
    return exsit;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( editingStyle == UITableViewCellEditingStyleDelete)
    {
        int index = indexPath.row;
        
        RootData *r= [RootData shared];
        NSArray *arr = [r getDataOfCurrMediaTypeVerifyFiltered];
        
        KxSMBItemFile *file = arr[index];
        
        BOOL exsit = false;
        
        NSString *fullFileName = [[RootData shared] smbFileExistsAtCache:file :&exsit];
        
        [[NSFileManager defaultManager] removeItemAtPath:fullFileName error:nil];
    }
}

#pragma mark -

-(void)playItemAtIndex:(int)index
{
    RootData *r= [RootData shared];
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
            auto size = [dicAttributes fileSize];
            
            if ( size == file.stat.size)
            {
                // Verify OK , play.
                [RootData shared].playingIndex = index;
                [_engine playURL: [NSURL fileURLWithPath:fullFileName]];
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
                 [_engine playURL: [NSURL fileURLWithPath:fullFileName]];
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


-(void)playNext
{
    [self stopAlbumRotation];
    
    int next = getNext(self.order, [RootData shared].playingIndex, 0, [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered].count );
    
    if (next != -1)
    {
        [self playItemAtIndex: next ];
    }
    
}

-(void)updateUI
{
    if ([self.engine isStopped])
    {
        [self.sliderProgress setSliderEnabled: false];
        
        self.sliderProgress.value = 0.;
        self.labelTitle.text = @"";
        
        self.btnPause.hidden = YES;
        self.btnPlay.hidden = FALSE;
        
        [self pauseAlbumRotation];
        
        [RootData shared].playingFilePath = nil;
        
        self.imageAlbumItem.hidden = FALSE;
        self.placeHolder.hidden=TRUE;
    }
    else
    {
        [self.sliderProgress setSliderEnabled: true];
        
        if ([self.engine isPlaying])
        {
            self.btnPause.hidden = FALSE;
            self.btnPlay.hidden = YES;
            
            [self startAlbumRotation];
        }
        else
        {
            self.btnPause.hidden = YES;
            self.btnPlay.hidden = FALSE;
            
            [self pauseAlbumRotation];
        }
    }
}

-(void)updateProgressInfo:(NSNotification*)n
{
    if (!self.sliderProgress.highlighted)
    {
        ProgressInfo *info = n.object;
        
        NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
        
        if (info.total > 0) {
            [self.sliderProgress setMaximumValue: info.total];
            [self.sliderProgress setValue: info.current];
        }
        
        int min , sec;
        
        valueToMinSec(info.current, &min, &sec);
        self.labelLeft.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
        
        valueToMinSec(info.total, &min, &sec);
        self.labelRight.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
        
        
    }
    

}



-(void)pauseAlbumRotation
{
    pauseLayer(self.imageAlbum.layer);
}

-(void)stopAlbumRotation
{
    [self.imageAlbum.layer removeAllAnimations];
}


-(void)startAlbumRotation
{
    if ([self.engine isPlaying])
    {
        if(![self.imageAlbum.layer animationForKey:@"rotationAnimation"] )
        {
            CFTimeInterval duration = 100 * 10 * 60 ;
            CABasicAnimation* rotationAnimation;
            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 0.15  * duration ];
            rotationAnimation.duration = duration;
            rotationAnimation.cumulative = YES;
            rotationAnimation.repeatCount = 1;
            
            [self.imageAlbum.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        }
        
        resumeLayer(self.imageAlbum.layer);
    }
}


-(void)setTitleAndAlbumImage
{
    NSMutableString *album = [ NSMutableString string];
    NSMutableString *artist = [ NSMutableString string];
    NSMutableString *title = [ NSMutableString string];
    
    RootData *r= [RootData shared];
    
    UIImage *image = getId3FromAudio( [NSURL fileURLWithPath: r.playingFilePath] , album, artist, title);
    
    if (image)
    {
        self.imageAlbumItem.hidden = YES;
        
        self.placeHolder.hidden = NO;
        
        UIImage *mask = [UIImage imageNamed:@"cd_mask5"];
        self.placeHolder.image = maskImage(image , mask);
    }

    
    self.labelTitle.text = title;
    self.NameOfSonger = artist;
    self.musicAlbumName = album;
    self.albumImageForBackground = self.placeHolder.image;
}


-(void)trackStarted:(NSNotification*)n
{
    ProgressInfo *info = n.object;
    NSAssert([info isKindOfClass:[ProgressInfo class]], nil);
    [self.sliderProgress setMaximumValue: info.total];
    [self.sliderProgress setValue: 0];

    [self setTitleAndAlbumImage];
    
    [self setPlayInfoWhenBeingBackground];
}

//add by zemeng
- (void) setPlayInfoWhenBeingBackground
{
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        info[MPMediaItemPropertyTitle] = self.labelTitle.text;  //歌曲名字
        info[MPMediaItemPropertyArtist] =self.NameOfSonger; //歌手
        info[MPMediaItemPropertyAlbumTitle] = self.musicAlbumName; //唱片名字
        info[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    
        if (self.albumImageForBackground) {
            info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.albumImageForBackground];
            
        }

        info[MPMediaItemPropertyLyrics] = @"123345ffdddffddd";
        info[MPMediaItemPropertyPlaybackDuration] = [NSString stringWithFormat:@"%f",[self.engine totalTime]];
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSString stringWithFormat:@"%f",[self.engine currentTime]];
    
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;

}

//- (void) setPlayingCurrentOnBackGround
//{
//    NSMutableDictionary * info = [NSMutableDictionary dictionary];
//    info[MPMediaItemPropertyTitle] = self.labelTitle.text;  //歌曲名字
//    info[MPMediaItemPropertyArtist] =self.NameOfSonger; //歌手
//    info[MPMediaItemPropertyAlbumTitle] = self.musicAlbumName; //唱片名字
//    info[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
//    
//    info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.albumImageForBackground];
//    info[MPMediaItemPropertyLyrics] = @"123345ffdddffddd";
//    info[MPMediaItemPropertyPlaybackDuration] = [NSString stringWithFormat:@"%f",[self.engine totalTime]];
//    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @"0";
//    
//    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
//}

#pragma mark - Controls Action

- (IBAction)actionOrder:(id)sender {
    self.order = playorder_repeat_list;
    self.btnOrder.selected = !self.btnOrder.selected;
}

- (IBAction)actionSingle:(id)sender {
    self.order = playorder_repeat_single;
    self.btnSingle.selected = !self.btnSingle.selected;
}

- (IBAction)actionShuffle:(id)sender {
    self.order = playorder_shuffle;
    self.btnRandom.selected = !self.btnRandom.selected;
}

- (IBAction)actionVolumn:(id)sender {
    [self.engine setVolume: self.sliderVolumn.value];
}

- (IBAction)actionProgress:(id)sender {
    [self.engine seekToTime:self.sliderProgress.value];
}

- (IBAction)actionPrev:(id)sender {
}

- (IBAction)actionPause:(id)sender {
    [self.engine playPause];
}

- (IBAction)actionPlay:(id)sender {
    [self.engine playPause];
    
    //add by zemeng
    [self setPlayInfoWhenBeingBackground];
}

- (IBAction)actionNext:(id)sender {
    postEvent(EventID_to_play_next, nil);
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touched Began");
    NSSet *set = [event touchesForView:self.imageAlbum];

    if ([set count] > 0)
    {
        [self pauseAlbumRotation];
    }
    
}

-(void)imageTouchesEnded
{
    [self startAlbumRotation];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touched End");
    NSSet *set = [event touchesForView:self.imageAlbum];
    
    if ([set count] > 0)
    {
        [self imageTouchesEnded];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touched Cancelled");
    NSSet *set = [event touchesForView:self.imageAlbum];
    if ([set count] > 0)
    {
        [self imageTouchesEnded];
    }
}

#pragma mark - supported rotations

/// Only support landscape  Interface Orientation if device if iPhone and iPod touch style.
-(NSUInteger)supportedInterfaceOrientations
{
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad )
    {
        return UIInterfaceOrientationMaskAll;
    }
    else
    {
       return UIInterfaceOrientationMaskLandscape;
    }
}


@end
