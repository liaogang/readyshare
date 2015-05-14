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

#import "PlayerMessage.h"
#import "PlayerEngine.h"

#import "RootData.h"

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




#import "PdfPreviewViewController.h"


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

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;

@property (weak, nonatomic) IBOutlet UILabel *downloadLabel;
@property (weak, nonatomic) IBOutlet UIView *placeHolderView;

@end

@implementation FileViewController {
    NSString        *_filePath;
    NSFileHandle    *_fileHandle;
    long            _downloadedBytes;
    NSDate          *_timestamp;
    
    bool isAddedBySuperView;
    CGRect rcNormal;
    
    int errorDownload;
    
    
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
    
    NSMutableData * _md;
    
#if !(TARGET_IPHONE_SIMULATOR)
    VDLViewController *_vcMoviePlayer;
#endif
    
    UIView *placeHolder;
}

@synthesize readyshareHomeVC;
- (void) dealloc
{
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    
    _nameLabel= nil ;
    _sizeLabel= nil ;
    _downloadProgress= nil ;
    _downloadLabel= nil ;
    _smbFile = nil;
    _filePath = nil ;
    web=nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
    
#if !(TARGET_IPHONE_SIMULATOR)
    [_vcMoviePlayer stop];
    _vcMoviePlayer = nil;
#endif
    
    [self closeFiles];
    placeHolder= nil;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewdidLoad: %p",self);
    
    self.navigationItem.title = self.smbFile.path.lastPathComponent;
    
    [self figureOutMediaType];
    
    [self performSelector:@selector(downloadAction) withObject:nil afterDelay:0.3];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoStarted) name:@"VDLViewControllerAboutToPlay" object:nil];
}

-(void)videoStarted
{
    self.navigationItem.rightBarButtonItem = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self ];
    
    [_vcMoviePlayer performSelector:@selector(actionFullScreen:) withObject:nil afterDelay:0.6];
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
    
    
    [self updateProgressLabel];
}


-(BOOL)isViewRemoved
{
    return  isAddedBySuperView && self.view.superview == nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
     isAddedBySuperView = true;
    
}



- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //is unlinked from superview?
    if([self isViewRemoved])
    {
#if !(TARGET_IPHONE_SIMULATOR)
        [_vcMoviePlayer stop];
#endif
        self.navigationController.title = nil ;
        
        
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
    
    NSLog(@"cloase Files.");
    
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
        
        _downloadLabel.text = @"";
        _downloadProgress.progress = 0;
        _downloadProgress.hidden = YES;
        _downloadLabel.text = @"Cancelled";
        [self closeFiles];
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
                               :NSLocalizedString(@"%@ %.1f%@ (%.1f%%) %.2f%@s      require %@",nil),
                               NSLocalizedString(@"downloaded ", nil),
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

-(void) updateDownloadStatus: (id) result
{
    if ([result isKindOfClass:[NSError class]]) {
        
        NSError *error = result;
        
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
               

                @try {
                    [_fileHandle writeData:data];
                }
                @catch (NSException *exception) {
                    NSLog(@"exception: %@",exception);
                    
                }
                @finally {
                    
                }
                
                
                
                
                //下载 完毕
                if(_downloadedBytes == _smbFile.stat.size) {
                    
                    [self closeFiles];
                    [self downloadComplete];
                    
                    if (_mediaType == video) {
                        self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(tryPlay)];
                    }
                } else
                {
                    [self updateProgressLabel];
                }
               
                
                //kSupportedFileExtensions
                if (_smbFile.stat.size >= 50*1024*1024)
                {
                    if( _mediaType  == video && !httpfileUrl)
                    {
                        //大于50或%10，播放预览
                        if( _downloadedBytes > 50*1024*1024 || _downloadProgress.progress *100 > 10 )
                            [self playVideo];
                    }
                }
                
            }
        }
    } else {
        
        NSAssert(false, @"bugcheck");
    }
}



-(void)tryPlay
{
    //is a video? played in vlc.
    if( !httpfileUrl )
        if ( _mediaType == video )
            [self playVideo];
    
    [self updateRightBarItem];
}

-(void)updateRightBarItem
{
#if !(TARGET_IPHONE_SIMULATOR)
    if ( [_vcMoviePlayer willPlay] ||  [_vcMoviePlayer isPlaying])
        self.navigationItem.rightBarButtonItem = nil;
#endif
}

-(void)downloadComplete
{
    //提醒用户下载完毕
    [MBProgressHUD showSuccess:NSLocalizedString(@"download finished", nil ) toView:self.navigationController.view];
    [self tryPlay];
   
#if !(TARGET_IPHONE_SIMULATOR)
    if (_mediaType == video) {
        if(_vcMoviePlayer.isPlaying)
        {
            return;
        }
    }
#endif
    self.navigationItem.rightBarButtonItem = nil;
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





-(BOOL)isDataAvaliable:(CGFloat)curr
{
    return  _smbFile.stat.size * curr < _downloadedBytes ;
}




-(void)playVideo
{
#if !(TARGET_IPHONE_SIMULATOR)
    if(httpfileUrl)
        return;
    
    // Pause music playing when play video.
    if ([[PlayerEngine shared] isPlaying])
        postEvent(EventID_to_play_pause_resume, nil);
    
    
    httpfileUrl = [NSURL fileURLWithPath:_filePath];

    
    _vcMoviePlayer = [[VDLViewController alloc]initWithNibName:@"VDLViewController" bundle:nil];
    [_vcMoviePlayer.view setFrame:self.placeHolderView.bounds];
    _vcMoviePlayer.view.autoresizingMask = ~0;
    _vcMoviePlayer.delegate=self;
    
    [_vcMoviePlayer setMedia:httpfileUrl];
    
    [self updateRightBarItem];
    
    [self.placeHolderView addSubview:_vcMoviePlayer.view];
    
    BOOL result = [_vcMoviePlayer play];
    
    NSLog(@"playing: %d",result);
    
#endif
}





@end
