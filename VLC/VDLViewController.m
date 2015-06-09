/* Copyright (c) 2013, Felix Paul Kühne and VideoLAN
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE. */

#import "VDLViewController.h"


#if !__has_feature(objc_arc)
#error VDLViewController.m is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define SYSTEM_RUNS_IOS7_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")



#if !(TARGET_IPHONE_SIMULATOR)

CGRect rectRorientation(CGRect r)
{
    CGRect t = {r.origin.y ,r.origin.x ,r.size.height , r.size.width};
    return t;
}



@interface VDLViewController () <UIGestureRecognizerDelegate>
{
    VLCMediaPlayer *_mediaplayer;
    
    ///占位视图,用于控制全屏退出时的位置
    UIView *_placeHolderView;
    
    BOOL bFullScreen;
    enum VLCRepeatMode bRepeat;
    NSURL *_url;
    UITapGestureRecognizer *_tapOnVideoRecognizer;
    BOOL _bControlsHiden;
    BOOL _viewAppeared;
    
    UIViewAutoresizing _autoresizingMask;
    
    UIPinchGestureRecognizer *_pinchRecognizer;
    int _performed;
}
- (IBAction)repeatBtnTouched:(id)sender;


///前进一小段
- (IBAction)fowardBtnTouched:(id)sender;
///后退xxx
- (IBAction)backBtnTouched:(id)sender;
///全屏按钮
- (IBAction)actionFullScreen:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnFullScreen;
///定位条
@property (retain, nonatomic) IBOutlet OBSlider *posSlider;
- (IBAction)posSliderChanged:(id)sender;
///xxx:xx显示定位
@property (retain, nonatomic) IBOutlet UIButton *posTextFieldRight;
@property (weak, nonatomic) IBOutlet UIButton *posTextFieldLeft;




///视频输出
@property (nonatomic, weak) IBOutlet UIView *movieView;




@property (retain, nonatomic) IBOutlet UIButton *btnBack;
@property (retain, nonatomic) IBOutlet UIButton *btnForward;
@property (retain, nonatomic) IBOutlet UIButton *btnPlayandPause;
///重复模式按钮
@property (retain, nonatomic) IBOutlet UIButton *btnRepeat;

- (IBAction)playandPause:(id)sender;
@end

@implementation VDLViewController



-(void)dealloc
{
    [_mediaplayer stop];
    _mediaplayer.delegate=nil;
    _mediaplayer = nil;
    
    
    [self.view removeGestureRecognizer:_pinchRecognizer];
    [self.view removeGestureRecognizer:_tapOnVideoRecognizer];
    _tapOnVideoRecognizer=nil;
    _pinchRecognizer = nil;
}
/*
 //在指定时间内没有事件发生,则隐藏控制栏
 -(void)hideControlsDelay
 {
 [self performSelector:@selector(_toggleControlsVisibleHIDE) withObject:nil afterDelay:3];
 
 _performed = TRUE;
 }
 */


/*
 - (void)_toggleControlsVisibleHIDE
 {
 [self _toggleControlsVisible:YES];
 }
 */


- (void)_toggleControlsVisible:(BOOL)bControlsHiden
{
    /*
     if(_performed == TRUE)
     {
     [NSObject cancelPreviousPerformRequestsWithTarget:self];
     _performed = NO;
     }
     
     //hide delay 3 after showed
     if(bControlsHiden == FALSE)
     {
     [self hideControlsDelay];
     }
     */
    
    _bControlsHiden = bControlsHiden;
    
    CGFloat alpha = bControlsHiden? 0.0f: 1.0f;
    
    
    void (^animationBlock)() = ^() {
        _btnFullScreen.alpha = alpha;
        _posSlider.alpha = alpha;
        _posTextFieldLeft.alpha = alpha;
        _posTextFieldRight.alpha = alpha;
        _btnBack.alpha = alpha;
        _btnForward.alpha = alpha;
        _btnPlayandPause.alpha = alpha;
        _btnRepeat.alpha = alpha;
    };
    
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        _btnFullScreen.hidden=bControlsHiden;
        _posSlider.hidden=bControlsHiden;
        _posTextFieldLeft.hidden=bControlsHiden;
        _posTextFieldRight.hidden=bControlsHiden;
        _btnBack.hidden=bControlsHiden;
        _btnForward.hidden=bControlsHiden;
        _btnPlayandPause.hidden=bControlsHiden;;
        _btnRepeat.hidden=bControlsHiden;
    };
    
    
    BOOL animated=YES;
    UIStatusBarAnimation animationType = animated? UIStatusBarAnimationFade: UIStatusBarAnimationNone;
    NSTimeInterval animationDuration = animated? 0.3: 0.0;
    
    [[UIApplication sharedApplication] setStatusBarHidden:_viewAppeared ? bControlsHiden : NO withAnimation:animationType];
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
}

- (void)toggleControlsVisible
{
    [self _toggleControlsVisible:!_bControlsHiden];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _posSlider.hidden=TRUE;
    
    self.view.backgroundColor = [UIColor blackColor];
    
    
    //hide or show controls.
    _tapOnVideoRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControlsVisible)];
    _tapOnVideoRecognizer.delegate = self;
    [self.view addGestureRecognizer:_tapOnVideoRecognizer];
    
    
    //全屏及退出的手势
    if(!_pinchRecognizer)
    {
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        _pinchRecognizer.delegate = self;
        [self.view addGestureRecognizer:_pinchRecognizer];
    }
    
    /* setup the media player instance, give it a delegate and something to draw into */
    _mediaplayer = [[VLCMediaPlayer alloc] init];
    _mediaplayer.delegate = self;
    _mediaplayer.drawable = self.movieView;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _viewAppeared=YES;
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    _viewAppeared = NO;
    if (!SYSTEM_RUNS_IOS7_OR_LATER)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];
}


-(void)setMedia:(NSURL*)url
{
    _url = url;
    _mediaplayer.media = [VLCMedia mediaWithURL:url];
}

- (IBAction)repeatBtnTouched:(id)sender {
    
    if (bRepeat == VLCDoNotRepeat) {
        bRepeat = VLCRepeatCurrentItem;
        [_btnRepeat setImage:[UIImage imageNamed:@"repeatOne"] forState:UIControlStateNormal];
    } else
    {
        bRepeat = VLCDoNotRepeat;
        [_btnRepeat setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
    }
    
}

- (IBAction)fowardBtnTouched:(id)sender {
    
    [_mediaplayer extraShortJumpForward];
}

- (IBAction)backBtnTouched:(id)sender {
    [_mediaplayer extraShortJumpBackward];
}

-(BOOL)play
{
    return [self _play] ;
}

-(BOOL)isPlaying
{
    return [_mediaplayer isPlaying];
}

-(BOOL)willPlay
{
    return [_mediaplayer willPlay];
}


-(BOOL)_play
{
    BOOL bRet = FALSE;
    if([_mediaplayer isPlaying])
    {
        [self pause];
    }
    else
    {
        if(_mediaplayer.state == VLCMediaPlayerStateStopped)
        {
            _mediaplayer.media = [VLCMedia mediaWithURL:_url];
        }
        
        bRet =  [_mediaplayer play];
    }
    
    
    return bRet  ;
}

- (IBAction)playandPause:(id)sender
{
    [self _play];
}

-(void)pause
{
    [_mediaplayer pause];
}

-(void)stop
{
    [_mediaplayer stop];
}

-(BOOL)bFullScreen
{
    return bFullScreen;
}

- (void)actionFullScreenBool:(BOOL)fullScreen
{
    //set view's auto resizing make to 'makeall' in fullscreen
    if(bFullScreen)
    {
        [UIApplication sharedApplication].keyWindow.rootViewController.navigationController.navigationBarHidden=TRUE;
        if(_autoresizingMask == 0)
            _autoresizingMask = self.view.autoresizingMask;
        self.view.autoresizingMask = ~0;
    }
    else
    {
        [UIApplication sharedApplication].keyWindow.rootViewController.navigationController.navigationBarHidden=FALSE;
        self.view.autoresizingMask=_autoresizingMask;
    }
    
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIView *rootView = rootVC.view;
    
    CGRect rcApp = [rootView frame];
    
    bool isLandscape = UIDeviceOrientationIsLandscape(self.interfaceOrientation);
    bool isLandscapeLeft = self.interfaceOrientation == UIDeviceOrientationLandscapeLeft;
    
    if(isLandscape){
        rcApp.size=CGSizeMake(rcApp.size.height, rcApp.size.width);
        if(isLandscapeLeft)
            rcApp.origin.x = rcApp.origin.y;
    }
    
    
    
    CGRect rc ;
    //to full screen
    if(bFullScreen)
    {
        _placeHolderView =  [[UIView alloc] initWithFrame:self.view.frame];
        _placeHolderView . autoresizingMask = self.view.autoresizingMask;
        _placeHolderView.backgroundColor=[UIColor clearColor];
        [self.view.superview addSubview:_placeHolderView];
        
        
        rc = [rootView convertRect:self.view.frame fromView:self.view.superview];
        [rootView addSubview:self.view];
        self.view.frame = rc;
        
        [[UIApplication sharedApplication]
         setStatusBarHidden:YES
         withAnimation:UIStatusBarAnimationFade];
        
        rc = rootView.bounds;
    }
    else
    { //to normal
        rc= [_placeHolderView.superview convertRect:_placeHolderView.frame toView:rootView];
        
        [[UIApplication sharedApplication]
         setStatusBarHidden:NO
         withAnimation:UIStatusBarAnimationFade];
    }
    
    __weak typeof (self) weakself = self;
    
    void(^animationBlock)() = ^()
    {
        [weakself.view setFrame:rc];
    };
    
    
    __weak typeof(_placeHolderView) weakPlaceHolder=_placeHolderView;
    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        if (!bFullScreen)
        {
            weakself.view.autoresizingMask=weakPlaceHolder.autoresizingMask;
            [weakself.view setFrame:weakPlaceHolder.frame];
            [weakPlaceHolder.superview addSubview:weakself.view];
            
            
            [weakPlaceHolder removeFromSuperview];
        }
        
        
        if(_fullScreenCallBack)
            _fullScreenCallBack(bFullScreen);
    };
    
    
    [UIView animateWithDuration:.5f animations:animationBlock completion:completionBlock];
}


- (IBAction)actionFullScreen:(id)sender {
    bFullScreen = !bFullScreen ;
    
    [self actionFullScreenBool: bFullScreen];
}


//exit full screen
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (recognizer.velocity < 0. && bFullScreen)
        [self actionFullScreen:nil];
    else if (recognizer.velocity > 0. && !bFullScreen)
        [self actionFullScreen:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setPos:(float)pos
{
    [_mediaplayer setPosition:pos];
}



- (IBAction)posSliderChanged:(id)sender {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    UISlider *slider = sender;
    NSLog(@"highlighted: %d",slider.highlighted);
    
    //notify pos will changed.
    
    BOOL bAvaliable = TRUE;
    
    if([_delegate respondsToSelector:@selector(isDataAvaliable:)])
    {
        bAvaliable= [_delegate isDataAvaliable:_posSlider.value];
        
        if(!bAvaliable)
        {
            [self pause];
            [_posSlider setValue: _mediaplayer.position];
            [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Source not avaliable", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok", nil), nil] show];
        }
    }
    
    
    if(bAvaliable)
        [_mediaplayer setPosition: _posSlider.value];
}

///用户正在拖动
-(BOOL)isUserSliding
{
    return _posSlider.state != UIControlStateNormal && _posSlider.highlighted == false;
}

-(void)mediaPlayerTimeChanged:(NSNotification *)aNotification
{
    BOOL bAvaliable = TRUE;
    
    if([_delegate respondsToSelector:@selector(isDataAvaliable:)])
        bAvaliable= [_delegate isDataAvaliable:_posSlider.value];
    
    
    if(!bAvaliable)
        [self pause];
    
    
    [self updatePosUI];
    
}

-(void)updatePosUI
{
    //do not update while user is operating.
    if(![self isUserSliding])
    {
        [_posSlider setValue: _mediaplayer.position];
        
        
        NSString *time = [_mediaplayer time].stringValue;
        NSString *remainingTime = [_mediaplayer remainingTime].stringValue;
        
        [_posTextFieldLeft setTitle:[NSString stringWithFormat:@"%@",time] forState:UIControlStateNormal];
        [_posTextFieldRight setTitle:[NSString stringWithFormat:@"%@",remainingTime] forState:UIControlStateNormal];
        
    }
}


- (void)mediaPlayerStateChanged:(NSNotification *)aNotification
{
    //update play or pause button's state.
    if (_mediaplayer.state == VLCMediaPlayerStatePlaying ||
        _mediaplayer.state ==VLCMediaPlayerStateOpening ||
        _mediaplayer.state ==VLCMediaPlayerStateBuffering )
    {
        _posTextFieldLeft.hidden=NO;
        _posTextFieldRight.hidden=NO;
        _posSlider.hidden=NO;
        [_btnPlayandPause setImage:[UIImage imageNamed:@"pauseIcon"] forState:UIControlStateNormal];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VDLViewControllerAboutToPlay" object:nil];
    }
    else
    {
        [_btnPlayandPause setImage:[UIImage imageNamed:@"playIcon"] forState:UIControlStateNormal];
    }
    
    if (_mediaplayer.state == VLCMediaPlayerStateStopped) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VDLViewControllerStopped" object:nil];
    }
    
    
    [self updatePosUI];
    
    
    //repeat play if reached the end.
    if(_mediaplayer.state == VLCMediaPlayerStateEnded ||VLCMediaPlayerStateStopped == _mediaplayer.state )
    {
        if(bRepeat)
        {
            _mediaplayer.media = [VLCMedia mediaWithURL:_url];
            [_mediaplayer setPosition:0.0];
            [_mediaplayer play];
        }
        else
        {
            _posTextFieldLeft.hidden=YES;
            _posTextFieldRight.hidden=YES;
            _posSlider.hidden=YES;
        }
    }
}


@end

#endif