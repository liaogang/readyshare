//
//  LocaFileSelectedViewController.m
//  GenieiPad
//
//  Created by geine on 14-3-27.
//
//

#include <sys/param.h>
#include <sys/mount.h>

#import "LocaFileSelectedViewController.h"
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MPMoviePlayerController.h>

#import "UIImage+UIImageExt.h"
#import "TreeViewController.h"

#define IOS_8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD                                                                \
([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@implementation LocaFileSelectedViewController {
    CGSize IMG_Size;
    MPMoviePlayerController *libMPlayer;
    __block BOOL fileCopyDone;
}
@synthesize uploadPathForLibItems;
@synthesize photosArray;
@synthesize fileNameArray;
@synthesize fileSizeArray;
@synthesize documentDirectory;

- (id)init {
    if (self = [super init]) {
        self.is_libFile = NO;
        fileCopyDone = NO;
        self.filePath = [[NSMutableString alloc] initWithCapacity:0];
        self.fileName = [[NSMutableString alloc] initWithCapacity:0];
        self.fileSize = [[NSMutableString alloc] initWithCapacity:0];
        photosArray = [[NSMutableArray alloc] initWithCapacity:0];
        fileNameArray = [[NSMutableArray alloc] initWithCapacity:0];
        fileSizeArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //防止播放文档后返回界面上移
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:NSLocalizedString(@"upload btn", nil)
                                              style:UIBarButtonItemStyleBordered
                                              target:self
                                              action:@selector(uploadFile)];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    self.title = self.fileName;
    
    NSString *nameSuffix = [self.fileName pathExtension];
    
    NSPredicate *filterImage =
    [NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] 'png'"];
    NSPredicate *filterVideo =
    [NSPredicate predicateWithFormat:
     @"SELF ENDSWITH[cd] 'mp4' || SELF ENDSWITH[cd] 'mov'"];
    
    // play media
    if ([self checkMedia:nameSuffix] || ([filterVideo evaluateWithObject:nameSuffix])) {
        [self playMedia];
    }
    // show image
    else if (!(self.is_libFile) && [self checkImages:nameSuffix]) {
        [self addSwipeGestureRecognizer];
        
        [self showImage:self.filePath];
    }
    // view document
    else if ([self checkWordDoc:nameSuffix]) {
        [self displayDocument:self.filePath];
    }
    // library photos
    else if ([filterImage evaluateWithObject:nameSuffix]) {
        [self addSwipeGestureRecognizer];
        
        [self libPhotoShow];
    }
    // other file what is not support
    else {
        [self showGeneralIco];
    }
}

- (BOOL)checkMedia:(NSString *)checkStr {
    return (([checkStr compare:@"mp3" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"aac" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"alac" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"m4a" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"mov" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"mp4" options:NSCaseInsensitiveSearch] == NSOrderedSame));
}

- (BOOL)checkImages:(NSString *)checkStr {
    return (([checkStr compare:@"jpg" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"bmp" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"jpeg" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"ico" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"gif" options:NSCaseInsensitiveSearch] == NSOrderedSame));
}

- (BOOL)checkWordDoc:(NSString *)checkStr {
    return (([checkStr compare:@"pdf" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"txt" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"rtf" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"doc" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"docx" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"xls" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"xlsx" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"ppt" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
            ([checkStr compare:@"pptx" options:NSCaseInsensitiveSearch] == NSOrderedSame));
}

//添加翻页手势
- (void)addSwipeGestureRecognizer {
    UISwipeGestureRecognizer *leftRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(swipPic:)];
    leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftRecognizer.delegate = self;
    UISwipeGestureRecognizer *rightRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(swipPic:)];
    rightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightRecognizer.delegate = self;
    [self.view addGestureRecognizer:leftRecognizer];
    [self.view addGestureRecognizer:rightRecognizer];
}

- (void)swipPic:(UISwipeGestureRecognizer *)recognizer {
    NSUInteger index;
    if (self.is_libFile) {
        index = [photosArray indexOfObject:[NSURL URLWithString:self.filePath]];
    } else {
        index = [photosArray indexOfObject:self.fileName];
    }
    
    //添加翻页动画
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (index != ([photosArray count] - 1)) {
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp
                                   forView:self.view
                                     cache:YES];
            
            [self.imageView removeFromSuperview];
            
            if (self.is_libFile) {
                self.fileName = [NSMutableString
                                 stringWithString:[fileNameArray objectAtIndex:(index + 1)]];
                self.fileSize = [NSMutableString
                                 stringWithString:[[fileSizeArray
                                                    objectAtIndex:(index + 1)] stringValue]];
                self.filePath = [NSMutableString
                                 stringWithString:[[photosArray
                                                    objectAtIndex:(index + 1)] absoluteString]];
                
                [self libPhotoShow];
            } else {
                self.fileName = [NSMutableString
                                 stringWithString:[photosArray objectAtIndex:(index + 1)]];
                self.filePath = [NSMutableString
                                 stringWithString:[documentDirectory
                                                   stringByAppendingFormat:@"/%@",
                                                   self.fileName]];
                
                [self showImage:self.filePath];
            }
            
            self.title = self.fileName;
        }
    } else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        if (index != 0) {
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown
                                   forView:self.view
                                     cache:YES];
            
            [self.imageView removeFromSuperview];
            
            if (self.is_libFile) {
                self.fileName = [NSMutableString
                                 stringWithString:[fileNameArray objectAtIndex:(index - 1)]];
                self.fileSize = [NSMutableString
                                 stringWithString:[[fileSizeArray
                                                    objectAtIndex:(index - 1)] stringValue]];
                self.filePath = [NSMutableString
                                 stringWithString:[[photosArray
                                                    objectAtIndex:(index - 1)] absoluteString]];
                
                [self libPhotoShow];
            } else {
                self.fileName = [NSMutableString
                                 stringWithString:[photosArray objectAtIndex:(index - 1)]];
                self.filePath = [NSMutableString
                                 stringWithString:[documentDirectory
                                                   stringByAppendingFormat:@"/%@",
                                                   self.fileName]];
                
                [self showImage:self.filePath];
            }
            
            self.title = self.fileName;
        }
    }
    
    [UIView commitAnimations];
}

#pragma mark - play media
- (void)playMedia {
    //本地文件和库文件由于路径格式不同，url的初始化方式也不同.
    NSURL *url;
    if (self.is_libFile) {
        url = [NSURL URLWithString:self.filePath];
    } else {
        url = [NSURL fileURLWithPath:self.filePath];
    }
    
    libMPlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        libMPlayer.view.frame =
        CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                   [UIScreen mainScreen].bounds.size.height - 100);
    } else {
        if (IOS_8 && !IS_IPAD) {
            libMPlayer.view.frame =
            CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                       [UIScreen mainScreen].bounds.size.height - 80);
        } else if (IOS_8 && IS_IPAD) {
            libMPlayer.view.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 80);
        } else {
            libMPlayer.view.frame =
            CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.height,
                       [UIScreen mainScreen].bounds.size.width - 80);
        }
    }
    
    [self.view addSubview:libMPlayer.view];
    [libMPlayer play];
    
    if (self.is_libFile) {
        [self creatLibVideoTemp];
    }
}

#pragma mark - image show
- (void)showImage:(NSString *)imgPath {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:imgPath];
    NSData *imagedata = [[NSData alloc] initWithContentsOfURL:url];
    
    UIImage *originImage = [UIImage imageWithData:imagedata];
    
    CGSize formatSize;
    
    if (((float)originImage.size.height / (float)originImage.size.width) < 2.0) {
        for (int i = 1; i < 20; ++i) {
            formatSize.width = originImage.size.width / i;
            formatSize.height = originImage.size.height / i;
            if (formatSize.width <= ([UIScreen mainScreen].bounds.size.width * 2) &&
                formatSize.height <= ([UIScreen mainScreen].bounds.size.height * 2)) {
                break;
            }
        }
    } else {
        QLPreviewController *previewoCntroller = [[QLPreviewController alloc] init];
        previewoCntroller.dataSource = self;
        
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
        backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
        self.navigationItem.backBarButtonItem = backBtn;
        
        [self.navigationController pushViewController:previewoCntroller
                                             animated:YES];
        [previewoCntroller setTitle:self.fileName];
        
        return;
    }
    
    UIImage *formatImage = [[UIImage alloc] init];
    
    formatImage = [originImage
                   imageByScalingAndCroppingForSize:CGSizeMake(formatSize.width,
                                                               formatSize.height)];
    
    IMG_Size = CGSizeMake(formatImage.size.width, formatImage.size.height);
    
    self.imageView = [[UIImageView alloc] initWithImage:formatImage];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = formatImage;
    self.imageView.tag = 1;
    
    
    [self.imageView setFrame:self.view.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.clipsToBounds=YES;
    [self.view addSubview:self.imageView];
    
    
    /*
     if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
     self.imageView.frame = CGRectMake(
     0, ([UIScreen mainScreen].bounds.size.height -
     IMG_Size.height * [UIScreen mainScreen].bounds.size.width /
     IMG_Size.width) /
     2,
     [UIScreen mainScreen].bounds.size.width,
     IMG_Size.height * [UIScreen mainScreen].bounds.size.width /
     IMG_Size.width);
     } else {
     
     
     
     
     
     if (IOS_8 && !IS_IPAD) {
     self.imageView.frame = CGRectMake(
     ([UIScreen mainScreen].bounds.size.width -
     IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
     IMG_Size.height) /
     2,
     ([UIScreen mainScreen].bounds.size.height -
     IMG_Size.width * [UIScreen mainScreen].bounds.size.width /
     IMG_Size.height) /
     2,
     IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
     IMG_Size.height,
     IMG_Size.width * [UIScreen mainScreen].bounds.size.width /
     IMG_Size.height);
     } else {
     self.imageView.frame = CGRectMake(
     0, ([UIScreen mainScreen].bounds.size.width -
     IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
     IMG_Size.height) /
     2,
     [UIScreen mainScreen].bounds.size.height,
     IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
     IMG_Size.height);
     }
     }
     
     
     */
}

#pragma mark - display document
- (void)displayDocument:(NSString *)DocPath {
    QLPreviewController *previewoCntroller = [[QLPreviewController alloc] init];
    previewoCntroller.dataSource = self;
    
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
    self.navigationItem.backBarButtonItem = backBtn;
    
    [self.navigationController pushViewController:previewoCntroller animated:YES];
    [previewoCntroller setTitle:self.fileName];
}

#pragma mark - show general ico when file is not support
- (void)showGeneralIco {
    UIImageView *imgV =
    [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    UIImage *img = [UIImage imageNamed:@"file.png"];
    imgV.image = img;
    
    [self.view addSubview:imgV];
}

#pragma mark - view life
- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                            duration:duration];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] ==
        NSNotFound) {
        [libMPlayer stop];
        libMPlayer = nil;
        self.filePath = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
        toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (IOS_8 && !IS_IPAD) {
            
            /*self.imageView.frame = CGRectMake(
             0, ([UIScreen mainScreen].bounds.size.width -
             IMG_Size.height * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.width) /
             2,
             [UIScreen mainScreen].bounds.size.height,
             IMG_Size.height * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.width);
             */
            libMPlayer.view.frame =
            CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.height,
                       [UIScreen mainScreen].bounds.size.width - 100);
        } else if (IOS_8 && IS_IPAD) {
            libMPlayer.view.frame =
            CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.height,
                       [UIScreen mainScreen].bounds.size.width - 100);
        } else {
            /* self.imageView.frame = CGRectMake(
             0, ([UIScreen mainScreen].bounds.size.height -
             IMG_Size.height * [UIScreen mainScreen].bounds.size.width /
             IMG_Size.width) /
             2,
             [UIScreen mainScreen].bounds.size.width,
             IMG_Size.height * [UIScreen mainScreen].bounds.size.width /
             IMG_Size.width);
             */
            libMPlayer.view.frame =
            CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                       [UIScreen mainScreen].bounds.size.height - 100);
        }
    } else {
        if (IOS_8 && !IS_IPAD) {
            /*   self.imageView.frame = CGRectMake(
             ([UIScreen mainScreen].bounds.size.height -
             IMG_Size.width * [UIScreen mainScreen].bounds.size.width /
             IMG_Size.height) /
             2,
             ([UIScreen mainScreen].bounds.size.width -
             IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.height) /
             2,
             IMG_Size.width * [UIScreen mainScreen].bounds.size.width /
             IMG_Size.height,
             IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.height);*/
        } else {
            /*   self.imageView.frame = CGRectMake(
             0, ([UIScreen mainScreen].bounds.size.width -
             IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.height) /
             2,
             [UIScreen mainScreen].bounds.size.height,
             IMG_Size.width * [UIScreen mainScreen].bounds.size.height /
             IMG_Size.height);*/
        }
        
        libMPlayer.view.frame =
        CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.height,
                   [UIScreen mainScreen].bounds.size.width - 80);
    }
}

#pragma mark - upload file
- (BOOL)checkUsbExist {
    //判断路由器上是否存在U盘
//    if (![TreeViewController RouterAccessalbe]) {
//        UIAlertView *alert = [[UIAlertView alloc]
//                              initWithTitle:nil
//                              message:NSLocalizedString(@"have no USB", nil)
//                              delegate:self
//                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
//                              otherButtonTitles:nil, nil];
//        [alert show];
//        return NO;
//    }
    return YES;
}

- (void)uploadFile {
    NSString *path;
    
    if (self.is_libFile) {
        if (!fileCopyDone) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:nil
                                  message:NSLocalizedString(@"no loaded", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        path = [[NSString alloc] initWithString:self.uploadPathForLibItems];
    } else {
        path = [[NSString alloc] initWithString:self.filePath];
    }
    
    if (![self checkUsbExist]) {
        return;
    }
    
//    TreeViewController *uploadView =
//    [[TreeViewController alloc] initAsHeadForUpoad:path];
//    uploadView.nav = self.navigationController;
    
    //自定义页面切换时的动画
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.navigationController.view.layer addAnimation:transition
                                                forKey:kCATransition];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
    backButton.title = NSLocalizedStringFromTable(@"back", @"Localizable", nil);
    self.navigationItem.backBarButtonItem = backButton;
    
    [libMPlayer stop];
    libMPlayer = nil;
    
    //[self.navigationController pushViewController:uploadView animated:NO];
}

#pragma mark - display library files
- (BOOL)checkDeviceFreeSpace {
    if (([self.fileSize longLongValue] * 2) >= [self freeDiskSpaceInBytes]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            self.navigationItem.rightBarButtonItem.tintColor = [UIColor grayColor];
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:nil
                              message:NSLocalizedString(@"device low space", nil)
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                              otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)creatLibVideoTemp {
    fileCopyDone = NO;
    
    if (![self checkDeviceFreeSpace]) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.filePath];
    
    NSString *temPath = NSTemporaryDirectory();
    NSString *uploadFileTempDirectory =
    [temPath stringByAppendingPathComponent:self.fileName];
    
    self.uploadPathForLibItems = uploadFileTempDirectory;
    
    dispatch_queue_t createTempQueue = dispatch_queue_create("createVideoTemp_queue", NULL);
    
    dispatch_async(createTempQueue, ^{
        [self.library assetForURL:url resultBlock:^(ALAsset *asset) {
            NSUInteger readSize = 1024 * 1024 * 2;
            NSUInteger sizeOfFile = [self.fileSize intValue];
            
            NSUInteger loop = sizeOfFile / readSize;
            NSUInteger lastSize = sizeOfFile % readSize;
            if (lastSize > 0) {
                loop++;
            }
            
            [[NSFileManager defaultManager] createFileAtPath:uploadFileTempDirectory contents:nil attributes:nil];
            NSFileHandle *videoHandle = [NSFileHandle fileHandleForWritingAtPath:uploadFileTempDirectory];
            if (!videoHandle) {
                NSLog(@"create file failed!");
                return;
            }
            [videoHandle truncateFileAtOffset:0];
            
            unsigned char *buffer = (unsigned char *)malloc(readSize);
            if (buffer == nil) {
                NSLog(@"malloc buffer failed!");
                return;
            }
            for (NSUInteger i = 0; i < loop; ++i) {
                BOOL is_lastSize = NO;
                
                [videoHandle seekToEndOfFile];
                
                if (i == (loop - 1) && lastSize > 0) {
                    is_lastSize = YES;
                    [[asset defaultRepresentation] getBytes:buffer fromOffset:(i * readSize) length:lastSize error:nil];
                } else {
                    [[asset defaultRepresentation] getBytes:buffer fromOffset:(i * readSize) length:readSize error:nil];
                }
                if (buffer) {
                    NSData *dataBuf;
                    if (is_lastSize) {
                        dataBuf = [NSData dataWithBytesNoCopy:buffer length:lastSize freeWhenDone:NO];
                    } else {
                        dataBuf = [NSData dataWithBytesNoCopy:buffer length:readSize freeWhenDone:NO];
                    }
                    [videoHandle writeData:dataBuf];
                }
            }
            free(buffer);
            buffer = NULL;
            
            [videoHandle closeFile];
            fileCopyDone = YES;
            
        }
                     failureBlock:^(NSError *error) { NSLog(@"test:Fail"); }];
    });
}

- (void)libPhotoShow {
    fileCopyDone = NO;
    
    NSURL *url = [NSURL URLWithString:self.filePath];
    
    NSString *temPath = NSTemporaryDirectory();
    NSString *uploadFileTempDirectory =
    [temPath stringByAppendingPathComponent:self.fileName];
    
    self.uploadPathForLibItems = uploadFileTempDirectory;
    
    [self.library assetForURL:url
                  resultBlock:^(ALAsset *asset) {
                      
                      ALAssetRepresentation *rep = [asset defaultRepresentation];
                      unsigned char *buffer = (unsigned char *)malloc((size_t)rep.size);
                      if (buffer == nil) {
                          UIAlertView *alert = [[UIAlertView alloc]
                                                initWithTitle:nil
                                                message:NSLocalizedString(@"load failed", nil)
                                                delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                otherButtonTitles:nil, nil];
                          [alert show];
                      }
                      
                      NSUInteger buffered = [rep getBytes:buffer
                                               fromOffset:0.0
                                                   length:(NSUInteger)rep.size
                                                    error:nil];
                      if (buffer) {
                          NSData *data = [NSData dataWithBytesNoCopy:buffer
                                                              length:buffered
                                                        freeWhenDone:NO];
                          
                          [data writeToFile:uploadFileTempDirectory atomically:YES];
                          fileCopyDone = YES;
                          [self showImage:uploadFileTempDirectory];
                      } else {
                          UIAlertView *alert = [[UIAlertView alloc]
                                                initWithTitle:nil
                                                message:NSLocalizedString(@"load failed", nil)
                                                delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                otherButtonTitles:nil, nil];
                          [alert show];
                      }
                      free(buffer);
                      buffer = NULL;
                      
                  }
                 failureBlock:^(NSError *error) { NSLog(@"test:Fail"); }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (libMPlayer) {
        [libMPlayer stop];
        libMPlayer = nil;
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.view = nil;
}

//用于播放文档
- (NSInteger)numberOfPreviewItemsInPreviewController:
(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller
                    previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:self.filePath];
}

//取得设备剩余空间
- (long long)freeDiskSpaceInBytes {
    struct statfs buf;
    long long freespace = -1;
    if (statfs("/var", &buf) >= 0) {
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    NSLog(@"%@", [NSString stringWithFormat:@"剩余存储空间为：%qi MB",
                  freespace / 1024 / 1024]);
    return freespace;
}
@end
