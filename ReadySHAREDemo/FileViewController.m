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

//#import "MJPhotoBrowser.h"
//#import "MJPhoto.h"
#include <math.h>

#import "constStrings.h"


#import "VDLViewController.h"
#import "PdfPreviewViewController.h"
//#import "RSHelper.h"

@interface FileViewController() <VLCViewData>

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
    UIImageView *_imageView2;
    UITapGestureRecognizer *_reg;
    
    
    NSURL *httpfileUrl;
    UIWebView *web;
    
    
    long   _lastDownloadedBytes;
    VDLViewController *_vcMoviePlayer;
    UIView *placeHolder;
}

@synthesize readyshareHomeVC;
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
    
    _filePath = nil ;
    
    _imageView = nil ;
    [_imageView2 removeFromSuperview];
    _imageView2=nil;
    _reg=nil;
    
    
    web=nil;
    
    [_vcMoviePlayer stop];
    _vcMoviePlayer = nil;
    placeHolder= nil;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
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
    
    
    self.navigationItem.title = self.smbFile.path.lastPathComponent;
    
    
    
    
    [self downloadAction];
}

-(void)PopSelfInNavAndSetNavPromptNil
{
    
}

//把文件从临时目录放到Downloads目录。
-(void)Save2Local
{
    //图片全屏时，按了”存储”不算。
    if(dwscViewIsFullScreen)
        return;
    
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
    
    NSString *filename = _smbFile.path.lastPathComponent;
    __block NSString *path2 = [folder stringByAppendingPathComponent:filename];
    
    NSFileManager *fm =[[NSFileManager alloc]init];
    
    [fm createDirectoryAtURL:[NSURL fileURLWithPath:folder]
 withIntermediateDirectories:YES attributes:nil error:nil ];
    
    if([fm fileExistsAtPath:path2])
    {
        __weak typeof(self) weakSelf = self;
        UIAlertViewBlock *alert = [[UIAlertViewBlock alloc] initWithTitle:NSLocalizedString(@"exists file", nil)
                                                                  message:nil
                                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil) cancelledBlock:^(UIAlertViewBlock *a){
                                                        }
                                                           okButtonTitles:NSLocalizedString(@"ok", nil) okBlock:^(UIAlertViewBlock *a){
                                                               [[NSFileManager defaultManager] removeItemAtPath:path2 error:nil];
                                                               
                                                               [weakSelf Save2Local2:path2];
                                                               
                                                           }];
        
        
        [alert show];
    }
    else
        [self Save2Local2:path2];
    
}



-(void)Save2Local2:(NSString*)path2
{
    NSLog(@"Copy File From :%@ to :%@",_filePath,path2);
    NSFileManager *fm =[[NSFileManager alloc]init];
    
    NSString *title;
    NSError *error = [[NSError alloc]init];
    if( [fm moveItemAtPath:_filePath toPath:path2 error:&error])
    {
        self.navigationItem.rightBarButtonItem = nil ;
        
        NSArray *pathComponents =path2.pathComponents;
        
        title = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"File Saved to :",nil),pathComponents[pathComponents.count-2]];
        
        [self closeFiles];
    }
    else
        title = error.description ;
    
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
        [alert show];
    }
    
    
    [self refreshLocalViewer];
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


-(BOOL)isViewRemoved
{
    return self.view.superview == nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //not poped
    if([self isViewRemoved])
    {
        [self closeMovie];

    }
    
    [_imageView2 removeFromSuperview];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //is unlinked from superview?
    if([self isViewRemoved])
    {
        [self closeMovie];
        [_vcMoviePlayer stop];
        self.navigationController.title = nil ;
        
        [self.view removeGestureRecognizer:_reg];
        
        [_imageView2 removeFromSuperview];
        
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
        
        NSLog(@"\n smb file size: %ld",_smbFile.stat.size);
        
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
        [self refreshLocalViewer];
        
        _downloadLabel.text = @"";
        _downloadProgress.progress = 0;
        _downloadProgress.hidden = YES;
        _downloadLabel.text = @"Cancelled";
        [self closeFiles];
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
                self.navigationItem.title=NSLocalizedString(@"File is Empty",nil);
                
                
                _downloadLabel.text = nil ;
                
                _downloadProgress.hidden=YES;
                
                [self closeFiles];
            }
        } else
        {
            NSTimeInterval time = -[_timestamp timeIntervalSinceNow];
            
            _downloadedBytes += data.length;
            _downloadProgress.progress = (float)_downloadedBytes / (float)_smbFile.stat.size;
            
            CGFloat value;
            NSString *unit;
            
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
            
            
            if (_fileHandle)
            {
                
                _downloadLabel.text = [NSString stringWithFormat:@"downloaded %.1f%@ (%.1f%%) %.2f%@s",
                                       value, unit,
                                       _downloadProgress.progress * 100.f,
                                       value / time, unit];
                
                [_fileHandle writeData:data];
                [_fileHandle synchronizeFile];
                
                
                //kSupportedFileExtensions
                if( !NSEqualRanges([kSupportedFileExtensions rangeOfString:[_smbFile.path.pathExtension lowercaseString]] , NSMakeRange(NSNotFound, 0)))
                //if([arrayMovieTypes containsObject:[[_smbFile.path pathExtension] lowercaseString]])
                {
                    //大于20或%20，播放预览
                    if( _downloadedBytes > 10*1024*1024 || _downloadProgress.progress *100 > 10 )
                    //if( _downloadedBytes > 20*1024*1024 || _downloadProgress.progress *100 > 25 )
                        //if(_downloadedBytes == _smbFile.stat.size)
                        [self playVideo];
                }
                
                
                //下载 完毕
                if(_downloadedBytes == _smbFile.stat.size) {
                    
                    [self closeFiles];
                    [self downloadComplete];
                    
                } else
                {
                    [self download];
                }
            }
        }
    } else {
        
        NSAssert(false, @"bugcheck");
    }
}

-(void)clearNavPromptWithDelay:(int)times
{
    __weak id wself = self;
    
    [self performSelector:@selector(clearNavPrompt:) withObject:wself afterDelay:times];
}

-(void)clearNavPromptWithDelay
{
    __weak id wself = self;
    
    [self performSelector:@selector(clearNavPrompt:) withObject:wself afterDelay:3];
}

-(void)clearNavPrompt:(__weak id)sender
{
    __strong __typeof__(self) sself = sender ;
    
    if(sself)
        sself.navigationItem.prompt = nil ;
}


-(void)downloadComplete
{
    self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(Save2Local)];
    
    
    //提醒用户下载完毕
    self.navigationItem.prompt = NSLocalizedString(@"download finished", nil );
    
    [self clearNavPromptWithDelay];
    
   
    //is a video? played in vlc.
    if(!httpfileUrl){
        //Picture
        if(  [arrayPictureTypes containsObject:[[_smbFile.path pathExtension] lowercaseString]] )
        {
            [self showPicture];
        }
        //QuickLook
        else if ([PdfPreviewViewController canPreviewItem:[NSURL fileURLWithPath: _filePath]])
        {
            [self showPdf];
        }
        else if([arrayMusicTypes containsObject:[[_smbFile.path pathExtension] lowercaseString]])
        {
            [self playMusic];
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
    _imageView.autoresizingMask = 0xffffffff & ~UIViewAutoresizingFlexibleTopMargin;
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
    CGRect rcApp = [self.navigationController.view frame];
    
    bool isLandscape = UIDeviceOrientationIsLandscape(self.interfaceOrientation);
    bool isLandscapeLeft = self.interfaceOrientation == UIDeviceOrientationLandscapeLeft;
    
    if(isLandscape){
        rcApp.size=CGSizeMake(rcApp.size.height, rcApp.size.width);
        if(isLandscapeLeft)
            rcApp.origin.x = rcApp.origin.y;
    }
    
    
    if(!_imageView2)
    {
        CGRect rc = [self.view convertRect:_imageView.frame toView:self.navigationController.view];
        
        _imageView2=[[UIImageView alloc]initWithFrame:rc];
        [_imageView2 setImage:_imageView.image];
        _imageView2.autoresizingMask = 0xffffffff ;
        _imageView2.clipsToBounds = YES;
        _imageView2.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.navigationController.view addSubview:_imageView2];
    }
    
    dwscViewIsFullScreen=!dwscViewIsFullScreen;
    _imageView2.hidden=NO;
     __weak typeof(self) weakSelf =self;
    __weak typeof(_imageView2) weakImageView = _imageView2;
    [UIView animateWithDuration:.5f animations:^{
        CGRect rc ;
        
        if(dwscViewIsFullScreen)
            rc = rcApp;
        else
            rc= [weakSelf.view convertRect:_imageView.frame toView:self.navigationController.view];
        
        [weakImageView setFrame:rc];
    } completion:^(BOOL finished) {
        if(!dwscViewIsFullScreen)
            weakImageView.hidden=YES;
    }];
    
}



- (void) download
{
    __weak __typeof(self) weakSelf = self;
    [_smbFile readDataOfLength:32768
                         block:^(id result)
     {
         FileViewController *p = weakSelf;
         if (p) {
             [p updateDownloadStatus:result];
         }
     }];
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
    if(httpfileUrl)
        return;
    
    httpfileUrl = [NSURL fileURLWithPath:_filePath];
    float ivW=self.view.frame.size.width,ivH=self.view.frame.size.height- 150;


    
    _vcMoviePlayer = [[VDLViewController alloc]initWithNibName:@"VDLViewController" bundle:nil];
    [_vcMoviePlayer.view setFrame:CGRectMake(0, 150, ivW, ivH)];
    _vcMoviePlayer.view.autoresizingMask = 0xffffffff & ~UIViewAutoresizingFlexibleTopMargin;
     _vcMoviePlayer.delegate=self;
    
    [_vcMoviePlayer setMedia:httpfileUrl];
    [_vcMoviePlayer play];
    
    [self.view addSubview:_vcMoviePlayer.view];
}




-(void)closeMovie
{
    [moviePlay stop];
    moviePlay=nil;
}


-(void)refreshLocalViewer
{

}
@end