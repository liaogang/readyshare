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


#import <UIKit/UIKit.h>
#import <MobileVLCKit/MobileVLCKit.h>
#import "OBSlider.h"
/**
*param bWillConvertToFullScreen ,是:当前正转换到全屏,否,相反.
*/
typedef void(^FullScreenCallBack)(BOOL bWillConvertToFullScreen );

@protocol VLCViewData <NSObject>
@optional
///用于正在下载的文件,返回播放进度是否没有超过了下载进度.
-(BOOL)isDataAvaliable:(CGFloat)curr;
@end


@interface VDLViewController : UIViewController <VLCMediaPlayerDelegate>
@property (nonatomic , assign  ) id<VLCViewData> delegate;



@property (retain, nonatomic) IBOutlet UIButton *btnFullScreen;
///定位条
@property (retain, nonatomic) IBOutlet OBSlider *posSlider;
- (IBAction)posSliderChanged:(id)sender;
///xxx:xx显示定位
@property (retain, nonatomic) IBOutlet UIButton *posTextField;




///视频输出
@property (nonatomic, strong) IBOutlet UIView *movieView;





@property (retain, nonatomic) IBOutlet UIButton *btnBack;
@property (retain, nonatomic) IBOutlet UIButton *btnForward;
@property (retain, nonatomic) IBOutlet UIButton *btnPlayandPause;
///重复模式按钮
@property (retain, nonatomic) IBOutlet UIButton *btnRepeat;






- (IBAction)playandPause:(id)sender;



-(void)play;
-(void)stop;


///全屏按钮
- (IBAction)actionFullScreen:(id)sender;
///全屏或退出全屏时的通知
@property (nonatomic,copy) FullScreenCallBack fullScreenCallBack;

///设置源
-(void)setMedia:(NSURL*)url;

-(void)setPos:(float)pos;


- (IBAction)repeatBtnTouched:(id)sender;


///前进一小段
- (IBAction)fowardBtnTouched:(id)sender;
///后退xxx
- (IBAction)backBtnTouched:(id)sender;

@end
