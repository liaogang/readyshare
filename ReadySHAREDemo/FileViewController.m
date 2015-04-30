//
//  FileViewController.m
//  kxsmb project
//  https://github.com/kolyvan/kxsmb/
//
//  Created by Kolyvan on 29.03.13.
//

#import "FileViewController.h"
#import "KxSMBProvider.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager+SMB.h"
#import "UIAlertViewBlock.h"
#import "UIImage+Resize.h"

#import "TreeViewController.h"


#include <math.h>

#import "constStrings.h"
#import "MBProgressHUD+Add.h"

#import <MediaPlayer/MPMoviePlayerController.h>

#import "PdfPreviewViewController.h"
#import "MAAssert.h"


/**
 * in iphone.os.sdk ==> #define TARGET_IPHONE_SIMULATOR     0
 * in iphone.simulator.sdk ==> #define TARGET_IPHONE_SIMULATOR     1
 * All defined , but the value is different, so use `#if` instead of `#ifdef`
 */

#if TARGET_IPHONE_SIMULATOR
#warning Using iPhone Simulator
#else
#warning Using Iphone Device.
#import "VDLViewController.h"
#endif



NSString *stringFromTimeInterval(NSTimeInterval t)
{
    unsigned long seconds = t;
    
    if (seconds == 0 ) {
        return @"less than a second";
    }
    
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    
    NSMutableString * result = [NSMutableString  string];
    
    if(hours)
        [result appendFormat: @"%d:", (int)hours];
    
    [result appendFormat: @"%02d:", (int)minutes];
    [result appendFormat: @"%02d", (int)seconds];
    
    return result;
}





@interface FileViewController()

#if !(TARGET_IPHONE_SIMULATOR)
<VLCViewData>
#endif
@property (strong,nonatomic)   UIImageView *imageView2;
@end

@implementation FileViewController {
    
    UILabel         *_nameLabel;
    UILabel         *_sizeLabel;
    UILabel         *_dateLabel;
    UIButton        *_downloadButton;
    UIProgressView  *_downloadProgress;
    UILabel         *_downloadLabel;
    NSString        *_filePath;
    NSFileHandle    *_fileHandle;
    long            _downloadedBytes;
    NSDate          *_timestamp;
    
    MPMoviePlayerController *moviePlay;
    BOOL dwscViewIsFullScreen;
    CGRect rcNormal;
    
    int errorDownload;
    
    UIImageView *_imageView;
    
    UITapGestureRecognizer *_reg;
    
    
    NSURL *httpfileUrl;
    UIWebView *web;
    
    enum mediaTypes
    {
        unknown,
        video,
        picture,
        audio,
    }
    _mediaType;
    
    long   _lastDownloadedBytes;
#if !(TARGET_IPHONE_SIMULATOR)
    VDLViewController *_vcMoviePlayer;
#endif
    
    
    bool isAddedBySuperView;
    
    NSMutableData * _md;
    
    
    UIDocumentInteractionController *_DocumentInteractionController;
    UIBarButtonItem *_shareBarButton ;
    UIBarButtonItem *_fixBarButton;
    UIBarButtonItem *_saveBarButton;
}

- (void) dealloc
{
    [_imageView setImageWithURL:[NSURL URLWithString:@"file:///abc"]];
    [self.view removeGestureRecognizer:_reg];
    
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    [self closeMovie];
    [self closeFiles];
    
    _nameLabel= nil ;
    _sizeLabel= nil ;
    _dateLabel= nil ;
    _downloadButton= nil ;
    _downloadProgress= nil ;
    _downloadLabel= nil ;
    _smbFile = nil;
    _filePath = nil ;
    
    _imageView = nil ;
    self.imageView2=nil;
    _reg=nil;
    
    
    web=nil;
    
#if !(TARGET_IPHONE_SIMULATOR)
    [_vcMoviePlayer stop];
    _vcMoviePlayer = nil;
#endif
    
    _DocumentInteractionController = nil ;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
    }
    return self;
}



- (void) loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    const float W = self.view.bounds.size.width;
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, W - 20, 40)];
    _nameLabel.font = [UIFont systemFontOfSize:14];
    _nameLabel.textColor = [UIColor darkTextColor];
    _nameLabel.opaque = NO;
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _nameLabel.numberOfLines = 2;
    _nameLabel.lineBreakMode=NSLineBreakByTruncatingMiddle;
    
    _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, W - 20, 30)];
    _sizeLabel.font = [UIFont systemFontOfSize:14];
    _sizeLabel.textColor = [UIColor darkTextColor];
    _sizeLabel.opaque = NO;
    _sizeLabel.backgroundColor = [UIColor clearColor];
    _sizeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, W - 20, 30)];
    _dateLabel.font = [UIFont systemFontOfSize:14];;
    _dateLabel.textColor = [UIColor darkTextColor];
    _dateLabel.opaque = NO;
    _dateLabel.backgroundColor = [UIColor clearColor];
    _dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    _downloadLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 110, W - 20, 30)];
    _downloadLabel.font = [UIFont systemFontOfSize:14];;
    _downloadLabel.textColor = [UIColor darkTextColor];
    _downloadLabel.opaque = NO;
    _downloadLabel.backgroundColor = [UIColor clearColor];
    _downloadLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _downloadLabel.numberOfLines = 2;
    
    _downloadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _downloadProgress.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    _downloadProgress.frame = CGRectMake(10, 100, W - 20, 30);
    _downloadProgress.hidden = YES;
    
    
    [self.view addSubview:_nameLabel];
    [self.view addSubview:_sizeLabel];
    [self.view addSubview:_dateLabel];
    [self.view addSubview:_downloadLabel];
    [self.view addSubview:_downloadProgress];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationItem.title = self.smbFile.path.lastPathComponent;
    
    
    [self figureOutMediaType];
    [self downloadAction];
}


-(void)figureOutMediaType
{
    NSAssert(_smbFile,nil);
    
    NSString *pathExtension = _smbFile.path.pathExtension.lowercaseString;
    
    
    NSRange r = [kSupportedFileExtensions rangeOfString:pathExtension];
    
    if( r.location != NSNotFound )
    {
        _mediaType = video;
    }
    else if(  [arrayPictureTypes containsObject:pathExtension] )
    {
        _mediaType = picture;
    }
    else if([arrayMusicTypes containsObject:pathExtension])
    {
        _mediaType = audio;
    }
    else
    {
        _mediaType = unknown;
    }
    
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _nameLabel.text = _smbFile.path;
    
    CGFloat value;
    NSString *unit;
    
    if (_smbFile.stat.size < 1024) {
        
        value = _smbFile.stat.size;
        unit = @"B";
        
    } else if (_smbFile.stat.size < 1048576) {
        
        value = _smbFile.stat.size / 1024.f;
        unit = @"KB";
        
    } else {
        
        value = _smbFile.stat.size / 1048576.f;
        unit = @"MB";
    }
    _sizeLabel.text = [NSString stringWithFormat:@"size: %.1f%@", value,unit];
    
    
    NSDate *date =_smbFile.stat.lastModified;
    
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc]init];
    [dateFormatter setDateStyle:kCFDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *fixString = [dateFormatter stringFromDate:date];
    
    _dateLabel.text = [NSString stringWithFormat:@"date: %@", fixString];
}


//return view is loaded and now removed.
-(BOOL)isViewRemoved
{
    return  isAddedBySuperView && self.view.superview == nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    isAddedBySuperView = true;
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //not poped
    if([self isViewRemoved])
    {
        [self closeMovie];
        
    }
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //is unlinked from superview?
    if([self isViewRemoved])
    {
        [self closeMovie];
#if !(TARGET_IPHONE_SIMULATOR)
        [_vcMoviePlayer stop];
#endif
        self.navigationController.title = nil ;
        
        [self.view removeGestureRecognizer:_reg];
        
        
        if(_fileHandle)
            [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    }
}



- (void) closeFiles
{
    if (_fileHandle) {
        [_fileHandle closeFile];
        
        _fileHandle = nil;
    }
    
    [_smbFile close];
}

- (void)downloadAction
{
    if (!_fileHandle)
    {
        
        NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                NSUserDomainMask,
                                                                YES) lastObject];
        
        
        NSFileManager *fm = [[NSFileManager alloc] init];
        
        //Open or Create A folder "Downloads"
        //folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
        
        [fm createDirectoryAtURL:[NSURL fileURLWithPath:folder]
     withIntermediateDirectories:YES attributes:nil error:nil ];
        
        
        NSString *filename = _smbFile.path.lastPathComponent;
        _filePath = [folder stringByAppendingPathComponent:filename];
        
#ifdef DEBUG
        NSLog(@"\n smb file size: %ld",_smbFile.stat.size);
#endif
        
        if ([fm fileExistsAtPath:_filePath])
            [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
        
        
        [fm createFileAtPath:_filePath contents:nil attributes:nil];
        
        NSError *error;
        _fileHandle = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:_filePath]
                                                        error:&error];
        
        if (_fileHandle)
        {
            _downloadLabel.text = @"starting ..";
            
            _downloadedBytes = 0;
            _downloadProgress.progress = 0;
            _downloadProgress.hidden = NO;
            _timestamp = [NSDate date];
            
            [self download];
            
            //[_downloadButton setTitle:@"Cancel" forState:UIControlStateNormal];
            
        } else
        {
            _downloadLabel.text = [NSString stringWithFormat:@"failed: %@", error.localizedDescription];
        }
    }
    else //User Cancel the download.
    {
        if(_fileHandle)
            [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
        
        [self closeFiles];
        
        _downloadLabel.text = @"";
        _downloadProgress.progress = 0;
        _downloadProgress.hidden = YES;
        _downloadLabel.text = @"Cancelled";
        //[_downloadButton setTitle:@"Download" forState:UIControlStateNormal];
    }
}

-(void) updateDownloadStatus: (id) result
{
    if ([result isKindOfClass:[NSError class]]) {
        
        NSError *error = result;
        
        [_downloadButton setTitle:@"Download" forState:UIControlStateNormal];
        _downloadLabel.text = [NSString stringWithFormat:@"failed: %@", error.localizedDescription];
        _downloadProgress.hidden = YES;
        [self closeFiles];
        
    } else if ([result isKindOfClass:[NSData class]]) {
        
        NSData *data = result;
        
        if (data.length == 0)
        {
            if(_downloadedBytes != _smbFile.stat.size)
            {
                
                if(errorDownload++<3)
                    [self download];
            }
            else
            {
                //提醒用户文件为空
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.labelText = NSLocalizedString(@"File is Empty",nil);
                // 再设置模式
                hud.mode = MBProgressHUDModeCustomView;
                // 隐藏时候从父控件中移除
                hud.removeFromSuperViewOnHide = YES;
                
                
                _downloadLabel.text = nil ;
                
                _downloadProgress.hidden=YES;
                
                [self closeFiles];
            }
        } else
        {
            _downloadedBytes += data.length;
            
            if (_fileHandle)
            {
                //下载 完毕
                if(_downloadedBytes == _smbFile.stat.size) {
                    [self updateProgressLabel];
                    [self closeFiles];
                    [self downloadComplete];
                    
                } else
                {
                    //[self download];
                    [self updateProgressLabel];
                }
                
                [_fileHandle writeData:data];
                
                
                
                //kSupportedFileExtensions
                /*
                if(   _mediaType  == video && !httpfileUrl)
                {
                    //大于20或%20，播放预览
                    if( _downloadedBytes > 10*1024*1024 || _downloadProgress.progress *100 > 10 )
                        [self playVideo];
                }
                */
                
                
            }
        }
    } else {
        
        NSAssert(false, @"bugcheck");
    }
}

-(void)updateProgressLabel
{
    NSTimeInterval time = -[_timestamp timeIntervalSinceNow];
    
    
    _downloadProgress.progress = (float)_downloadedBytes / (float)_smbFile.stat.size;
    
    CGFloat value;
    NSString *unit;
    
    
    if (_downloadedBytes < _smbFile.stat.size)
    {
        
        
        if (_downloadedBytes < 1024) {
            
            value = _downloadedBytes;
            unit = @"B";
            
        } else if (_downloadedBytes < 1048576) {
            
            value = _downloadedBytes / 1024.f;
            unit = @"KB";
            
        } else {
            value = _downloadedBytes / 1048576.f;
            unit = @"MB";
        }
        
        NSTimeInterval timeRequire = (_smbFile.stat.size - _downloadedBytes) * time / _downloadedBytes ;
        
        // downloaded d(S) c(P) c(s)
        _downloadLabel.text = [NSString stringWithFormat
                               :NSLocalizedString(@"downloaded %.1f%@ (%.1f%%) %.2f%@s      require %@",nil),
                               value, unit,
                               _downloadProgress.progress * 100.f,
                               value / time, unit  , stringFromTimeInterval(timeRequire)];
    }
    else
    {
        //download complete
        _downloadLabel.text =[NSString stringWithFormat:
                              NSLocalizedString(@"download completed in %@",nil) , stringFromTimeInterval(time) ];
    }
    
    
    
    //[_fileHandle synchronizeFile];
}

-(void)downloadComplete
{
    if (!self.navigationItem.rightBarButtonItems)
    {
        _saveBarButton =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(Save2Local)];
        
        _fixBarButton =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        
        
        _shareBarButton =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showDocumentInteractionMenu:)];
        
        self.navigationItem.rightBarButtonItems=@[_shareBarButton,_fixBarButton,_saveBarButton];
    }
    
    
    //提醒用户下载完毕
    [MBProgressHUD showSuccess:NSLocalizedString(@"download finished", nil ) toView:self.navigationController.view];
    
    //is a video? played in vlc.
    if( !httpfileUrl )
    {
        if ( _mediaType == video )
        {
            [self playVideo];
        }
        else
            //Picture
            if(  _mediaType == picture )
            {
                [self showPicture];
            }
            else if(_mediaType == audio )
            {
                [self playMusic];
            }
        //QuickLook
            else if ([PdfPreviewViewController canPreviewItem:[NSURL fileURLWithPath: _filePath]])
            {
                //show a reopen menu in right bar.
                UIButton *reopen = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                reopen.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
                
                [reopen setTitle:NSLocalizedString(@"Open with QuickLook",nil) forState:UIControlStateNormal];
                [reopen addTarget:self action:@selector(showPdf) forControlEvents:UIControlEventTouchUpInside];
                float ivW=self.view.frame.size.width,ivH=self.view.frame.size.height- 150;
                [reopen setFrame:CGRectMake(0, 0, 200 , 50)];
                reopen.center=CGPointMake(ivW /2 , ivH /2 + 150);
                [self.view addSubview:reopen];
            }
    }
    
}









-(void)showPicture
{
    float ivW=self.view.frame.size.width,ivH=self.view.frame.size.height- 150;
    UIImage *image=[UIImage imageWithContentsOfFile:_filePath];
    CGFloat t = image.size.width *image.size.height;
    
    if( t > 2048 * 2048 )
    {
        image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(ivW, ivH) interpolationQuality:kCGInterpolationHigh];
    }
    
    _imageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 150, ivW, ivH)];
    [_imageView setImage:image];
    _imageView.autoresizingMask =  ~UIViewAutoresizingFlexibleTopMargin;
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_imageView];
    
    
    
    _reg=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapped)];
    _reg.numberOfTapsRequired=1;
    [self.view addGestureRecognizer:_reg];
}

// 全屏
-(void)tapped
{
    CGRect rcBounds = self.navigationController.view.bounds;
    
    MAAssert(dwscViewIsFullScreen == false ? self.imageView2.superview == nil: true);
    
    if (self.imageView2 == nil)
    {
        CGRect rcF = [self.view convertRect:_imageView.frame toView:self.navigationController.view];
        self.imageView2=[[UIImageView alloc]initWithFrame:rcF];
        [_imageView2 setImage:_imageView.image];
        _imageView2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
        _imageView2.clipsToBounds = YES;
        _imageView2.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.navigationController.view addSubview:_imageView2];
    }
    
    
    
    __weak typeof(self) weakSelf =self;
    __weak typeof(_imageView2) weakImageView = _imageView2;
    dwscViewIsFullScreen=!dwscViewIsFullScreen;
    [UIView animateWithDuration:.5f animations:^{
        CGRect rc ;
        
        if(dwscViewIsFullScreen)
            rc = rcBounds;
        else
            rc= [weakSelf.view convertRect:_imageView.frame toView:self.navigationController.view];
        
        [weakImageView setFrame:rc];
        
    } completion:^(BOOL finished)
     {
         if(!dwscViewIsFullScreen)
         {
             weakImageView.hidden=YES;
             [weakImageView removeFromSuperview];
             weakSelf.imageView2=nil;
         }
     }];
    
}


-(void)downloadThread
{
    NSCondition *condition ;
    condition = [[NSCondition alloc]init];
    
    _md = [NSMutableData data];
    
    static BOOL bEnd ;
    bEnd = FALSE;
    
    [_smbFile readDataToEndOfFileEx:_md condition:condition bEnd:&bEnd];
    
    __weak typeof(self) weakSelf = self;
    
    while (1)
    {
        if (!weakSelf || [self isViewRemoved] )
        {
            bEnd = READ_DATA_FLAG_END;
            _md  = nil ;
            if(_fileHandle)
                [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
            
            [self closeFiles];
            break;
        }
        
        [condition lock];
        
        while (bEnd<=0)
            [condition wait];
        
        if (bEnd--==READ_DATA_FLAG_END)
        {
            [self performSelectorOnMainThread:@selector(updateDownloadStatus:) withObject:_md waitUntilDone:FALSE];
            [condition unlock];
            break;
        }
        else
        {
            NSMutableData *data = [NSMutableData dataWithData:_md];
            [self performSelectorOnMainThread:@selector(updateDownloadStatus:) withObject:data waitUntilDone:FALSE];
            
            [condition unlock];
        }
    }
    
}


- (void) download
{
    [self performSelectorInBackground:@selector(downloadThread) withObject:nil];
}




-(void)showPdf
{
    PdfPreviewViewController *pdf =[[PdfPreviewViewController alloc]initWithFilePaths:@[[NSURL fileURLWithPath: _filePath]]];
    [self.navigationController pushViewController:pdf animated:YES];
}

-(void)playMusic
{
    if(moviePlay)
        return;
    
    moviePlay=[[MPMoviePlayerController alloc]initWithContentURL:[NSURL fileURLWithPath:_filePath]];
    moviePlay.view.frame = CGRectMake(0, 160, self.view.frame.size.width, self.view.frame.size.height-160);
    moviePlay.shouldAutoplay = YES;
    moviePlay.scalingMode = MPMovieScalingModeAspectFit;
    
    moviePlay.repeatMode=MPMovieRepeatModeOne;
    [moviePlay prepareToPlay];
    moviePlay.view.autoresizingMask = 0xffffffff & ~UIViewAutoresizingFlexibleTopMargin;
    
    [self.view addSubview:moviePlay.view];
}


-(BOOL)isDataAvaliable:(CGFloat)curr
{
    return  _smbFile.stat.size * curr < _downloadedBytes ;
}


-(void)playVideo
{
#if !(TARGET_IPHONE_SIMULATOR)
    httpfileUrl = [NSURL fileURLWithPath:_filePath];
    float ivW=self.view.frame.size.width,ivH=self.view.frame.size.height- 150;
    
    
    _vcMoviePlayer = [[VDLViewController alloc]initWithNibName:@"VDLViewController" bundle:nil];
    [_vcMoviePlayer.view setFrame:CGRectMake(0, 150, ivW, ivH)];
    _vcMoviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
    
    _vcMoviePlayer.delegate=self;
    
    [_vcMoviePlayer setMedia:httpfileUrl];
    
    
    [_vcMoviePlayer play];
    
    [self.view addSubview:_vcMoviePlayer.view];
#endif
}

-(void)showHudMsg:(NSString*)str
{
    [MBProgressHUD showError:str toView:self.navigationController.view];
}

-(void)showHudMsgInMainThread:(NSString*)str
{
    MAAssert([NSThread isMainThread]);
    
    [self performSelectorOnMainThread:@selector(showHudMsg:) withObject:str waitUntilDone:NO];
}


-(void)closeMovie
{
#if !(TARGET_IPHONE_SIMULATOR)
    [_vcMoviePlayer.view removeFromSuperview];
#endif
    
    
    [moviePlay stop];
    moviePlay=nil;
}






#pragma mark - UIDocumentInteraction Action

-(void)showDocumentInteractionMenu:(id)sender
{
    if (!_DocumentInteractionController)
    {
        _DocumentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_filePath]];
    }
    
    
    [_DocumentInteractionController presentOpenInMenuFromBarButtonItem:sender animated:YES];
}


@end
