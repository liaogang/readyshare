//
//  LocalViewController.m
//  GenieiPhoneiPod
//
//  Created by lixiang on 14-2-24.
//
//

#import "LocalViewController.h"
#import "TreeViewController.h"

#import "UIImage+UIImageExt.h"

#import "LocaFileSelectedViewController.h"
//#import "audioTableViewController.h"
#import "DoImagePickerController.h"

#ifdef __llvm__
#pragma GCC diagnostic ignored "-Wdangling-else"
#endif

#ifdef __GENIE_IPHONE__

#define iOSDeviceScreenWidth 320
#define iOSDeviceScreenHeight                                                  \
(CGSizeEqualToSize(CGSizeMake(640, 1136),                                    \
[[UIScreen mainScreen] currentMode].size)                 \
? 568                                                                   \
: 480)
#define iOSStatusBarHeight 20
#define Navi_Bar_Height_Portrait 44
#define Navi_Bar_Height_Landscape 32

#else

#define iOSDeviceScreenWidth 768
#define iOSDeviceScreenHeight 1024
#define iOSStatusBarHeight 20
#define Navi_Bar_Height_Portrait 44
#define Navi_Bar_Height_Landscape 44

#endif

#define CGZero 0.0

static NSMutableArray *m_imageArray;
static BOOL is_editing = NO;
static NSString *playFileName;

@implementation LocalViewController
@synthesize remoteViewC;
@synthesize navController;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        is_editing = NO;
        
        // create folders
        NSFileManager *fm = [[NSFileManager alloc] init];
        
        NSString *folder = [NSSearchPathForDirectoriesInDomains(
                                                                NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
        NSString *photoFolder =
        [[NSString alloc] initWithFormat:@"%@/Local Photo Library", folder];
//        NSString *videoFolder =
//        [[NSString alloc] initWithFormat:@"%@/Local Video Library", folder];
        
        
        //        NSString *audioFolder = [folder
        //        stringByAppendingPathComponent:@"Audio Library"];
        //        //暂时屏蔽audio目录，因为My media中没有music
        
        [fm createDirectoryAtURL:[NSURL fileURLWithPath:photoFolder]
     withIntermediateDirectories:YES
                      attributes:nil
                           error:nil];
//        [fm createDirectoryAtURL:[NSURL fileURLWithPath:videoFolder]
//     withIntermediateDirectories:YES
//                      attributes:nil
//                           error:nil];
        
        //        [fm createDirectoryAtURL:[NSURL fileURLWithPath:audioFolder]
        //     withIntermediateDirectories:YES attributes:nil error:nil ];
    }
    return self;
}

- (id)initWithDirectoryPaths:(NSString *)path {
    self = [super init];
    if (self) {
        m_documentDirectory = path;
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"refreshLocalViewer"
                                                  object:nil];
    remoteViewC = nil;
    navController = nil;
    
    m_filesArray = nil;
    m_sizeArray = nil; // file size in dir
    m_tableView = nil;
    m_documentDirectory = nil;
    m_fileManager = nil;
    m_fileName = nil;
}
- (void)loadView {
    [super loadView];
    
    m_tableView = [[UITableView alloc]
                   initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    m_tableView.delegate = self;
    m_tableView.dataSource = self;
    //检测系统版本，ios6里使用tintColor会crash
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        m_tableView.tintColor = [UIColor blackColor];
    }
    [self showViewWithOrientation:self.interfaceOrientation];
    
    self.view = m_tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    m_rowCurr = -1;
    
    m_fileManager = [NSFileManager defaultManager];
    
    [self ReloadData];
    
    // by lg
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(refreshLocalViewer:)
     name:@"refreshLocalViewer"
     object:nil];
}

- (void)refreshLocalViewer:(NSNotification *)o {
    NSString *path = o.object;
    
    if (path == nil || [path isEqualToString:m_documentDirectory])
        [self ReloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self ReloadData];
}

- (void)ReloadData {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(
                                                                  NSDocumentDirectory, NSUserDomainMask, YES);
    
    // 传递 0 代表是找在Documents 目录下的文件。
    if (m_documentDirectory == nil) {
        m_documentDirectory = [directoryPaths objectAtIndex:0];
    }
    
    //枚举当前目录下的文件
    m_filesArray = (NSMutableArray *)
    [m_fileManager contentsOfDirectoryAtPath:m_documentDirectory error:nil];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                              target:self
                                              action:@selector(trashButtonPress)];
    
    m_sizeArray = [[NSMutableArray alloc] init];
    
    for (NSString *path in m_filesArray) {
        NSDictionary *file = [m_fileManager
                              attributesOfItemAtPath:[m_documentDirectory
                                                      stringByAppendingFormat:@"/%@", path]
                              error:nil];
        [m_sizeArray
         addObject:[[NSNumber alloc] initWithUnsignedLongLong:[file fileSize]]];
    }
    
    self.navigationItem.title = m_documentDirectory.lastPathComponent;
    
    [m_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// hide empty rows
- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (void)showViewWithOrientation:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        m_tableView.frame = CGRectMake(CGZero, CGZero, iOSDeviceScreenWidth,
                                       iOSDeviceScreenHeight - iOSStatusBarHeight -
                                       Navi_Bar_Height_Portrait - 49);
    } else if (UIInterfaceOrientationIsLandscape(orientation)) {
        m_tableView.frame = CGRectMake(CGZero, CGZero, iOSDeviceScreenHeight,
                                       iOSDeviceScreenWidth - iOSStatusBarHeight -
                                       Navi_Bar_Height_Landscape - 49);
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    [self showViewWithOrientation:toInterfaceOrientation];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        NSString *filename = [m_filesArray objectAtIndex:[indexPath row]];
        NSString *fullFilePath =
        [m_documentDirectory stringByAppendingFormat:@"/%@", filename];
        if ([m_fileManager fileExistsAtPath:fullFilePath]) {
            [m_fileManager removeItemAtPath:fullFilePath error:nil];
            [m_filesArray removeObjectAtIndex:[indexPath row]];
        }
        [tableView reloadData];
        [self ReloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}

#pragma mark table delegate and data source

//推出设置界面
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    
//    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil message:@"将会在下个版本中支持，敬请关注"
//                                                   delegate:self
//                                          cancelButtonTitle:NSLocalizedString(@"确定",nil)
//                                          otherButtonTitles:nil, nil];
//    //                alert.tag = AlertView_RebootRouter_Tag;
//    [alert show];
//    //[alert release];
//    return;
//    
//    NSInteger row = [indexPath row];
//    NSString *newPath = [m_documentDirectory
//                         stringByAppendingFormat:@"/%@", [m_filesArray objectAtIndex:row]];
//    
//    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
//    backItem.title = NSLocalizedStringFromTable(@"back", @"Localizable", nil);
//    self.navigationItem.backBarButtonItem = backItem;
//    
//    BOOL isDir, valid;
//    valid = [[NSFileManager defaultManager] fileExistsAtPath:newPath
//                                                 isDirectory:&isDir];
//    
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//    
//    if (valid)
//        if (isDir) {
//            NSString *folderPhoto = [m_documentDirectory
//                                     stringByAppendingFormat:@"/%@", @"Photo Library"];
//            NSString *folderVideo = [m_documentDirectory
//                                     stringByAppendingFormat:@"/%@", @"Video Library"];
//            
//            //            NSString *folderAudio = [m_documentDirectory
//            //            stringByAppendingPathComponent:@"Audio Library"];
//            
//            // come to library
//            if ([newPath isEqualToString:folderPhoto] ||
//                [newPath isEqualToString:folderVideo]) {
//                BOOL is_pic = NO;
//                if ([newPath isEqualToString:folderPhoto]) {
//                    is_pic = YES;
//                } else {
//                    is_pic = NO;
//                }
//                
//                LocalLibraryViewController *libView =
//                [[LocalLibraryViewController alloc] initWithTag:is_pic];
//                libView.folderName = cell.textLabel.text;
//                
//                UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
//                backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
//                self.navigationItem.backBarButtonItem = backBtn;
//                
//                [self.navController pushViewController:libView animated:YES];
//            }
//            //            else if([newPath isEqualToString:folderAudio])
//            //            {
//            //                audioTableViewController *a =[[audioTableViewController
//            //                alloc]init ];
//            //                [a setDirectory:folderAudio];
//            //                [self.navController pushViewController:a animated:YES];
//            //            }
//            else {
//                LocalViewController *local =
//                [[LocalViewController alloc] initWithDirectoryPaths:newPath];
//                local.navController = self.navController;
//                [self.navController pushViewController:local animated:YES];
//                local.remoteViewC = self.remoteViewC;
//            }
//        } else // if file
//        {
//            playFileName = [m_filesArray objectAtIndex:row];
//            
//            [self uploadOrPlay:[m_documentDirectory
//                                stringByAppendingFormat:
//                                @"/%@", [m_filesArray objectAtIndex:row]]];
//        }
//}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil message:@"将会在下个版本中支持，敬请关注"
//                                                   delegate:self
//                                          cancelButtonTitle:NSLocalizedString(@"确定",nil)
//                                          otherButtonTitles:nil, nil];
//    //                alert.tag = AlertView_RebootRouter_Tag;
//    [alert show];
//    //[alert release];
//    return;
    
    NSInteger row = [indexPath row];
    NSString *newPath = [m_documentDirectory
                         stringByAppendingFormat:@"/%@", [m_filesArray objectAtIndex:row]];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
    backItem.title = NSLocalizedStringFromTable(@"back", @"Localizable", nil);
    self.navigationItem.backBarButtonItem = backItem;
    
    BOOL isDir, valid;
    valid = [[NSFileManager defaultManager] fileExistsAtPath:newPath
                                                 isDirectory:&isDir];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (valid)
        if (isDir) {
            NSString *folderPhoto = [m_documentDirectory
                                     stringByAppendingFormat:@"/%@", @"Photo Library"];
            NSString *folderVideo = [m_documentDirectory
                                     stringByAppendingFormat:@"/%@", @"Video Library"];
            
            //            NSString *folderAudio = [m_documentDirectory
            //            stringByAppendingPathComponent:@"Audio Library"];
            
            // come to library
            if ([newPath isEqualToString:folderPhoto] ||
                [newPath isEqualToString:folderVideo]) {
                BOOL is_pic = NO;
                if ([newPath isEqualToString:folderPhoto]) {
                    is_pic = YES;
                } else {
                    is_pic = NO;
                }
                
//                LocalLibraryViewController *libView =
//                [[LocalLibraryViewController alloc] initWithTag:is_pic];
//                libView.folderName = cell.textLabel.text;
                DoImagePickerController *cont = [[DoImagePickerController alloc] initWithNibName:@"DoImagePickerController" bundle:nil];
                cont.delegate = self;
                //    cont.nResultType = DO_PICKER_RESULT_UIIMAGE;
                //    if (_sgMaxCount.selectedSegmentIndex == 0)
                //        cont.nMaxCount = 1;
                //    else if (_sgMaxCount.selectedSegmentIndex == 1)
                //        cont.nMaxCount = 4;
                //    else if (_sgMaxCount.selectedSegmentIndex == 2)
                //    {
                //        cont.nMaxCount = DO_NO_LIMIT_SELECT;
                //        cont.nResultType = DO_PICKER_RESULT_ASSET;  // if you want to get lots photos, you'd better use this mode for memory!!!
                //    }
                cont.nMaxCount = DO_NO_LIMIT_SELECT;
                cont.nResultType = DO_PICKER_RESULT_ASSET;
                cont.nColumnCount = 2;//_sgColumnCount.selectedSegmentIndex + 2;
                
                //[self presentViewController:cont animated:YES completion:nil];
                
                UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
                backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
                self.navigationItem.backBarButtonItem = backBtn;
                //[self.navController pushViewController:libView animated:YES];
                [self.navController pushViewController:cont animated:YES];
            }
            //            else if([newPath isEqualToString:folderAudio])
            //            {
            //                audioTableViewController *a =[[audioTableViewController
            //                alloc]init ];
            //                [a setDirectory:folderAudio];
            //                [self.navController pushViewController:a animated:YES];
            //            }
            else {
//                LocalViewController *local =
//                [[LocalViewController alloc] initWithDirectoryPaths:newPath];
//                local.navController = self.navController;
//                [self.navController pushViewController:local animated:YES];
//                local.remoteViewC = self.remoteViewC;
                
                
                DoImagePickerController *cont = [[DoImagePickerController alloc] initWithNibName:@"DoImagePickerController" bundle:nil];
                cont.delegate = self;
                //    cont.nResultType = DO_PICKER_RESULT_UIIMAGE;
                //    if (_sgMaxCount.selectedSegmentIndex == 0)
                //        cont.nMaxCount = 1;
                //    else if (_sgMaxCount.selectedSegmentIndex == 1)
                //        cont.nMaxCount = 4;
                //    else if (_sgMaxCount.selectedSegmentIndex == 2)
                //    {
                //        cont.nMaxCount = DO_NO_LIMIT_SELECT;
                //        cont.nResultType = DO_PICKER_RESULT_ASSET;  // if you want to get lots photos, you'd better use this mode for memory!!!
                //    }
                cont.nMaxCount = DO_NO_LIMIT_SELECT;
                cont.nResultType = DO_PICKER_RESULT_ASSET;
                cont.nColumnCount = 2;//_sgColumnCount.selectedSegmentIndex + 2;
                
                [self presentViewController:cont animated:YES completion:nil];
                
//                UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
//                backBtn.title = NSLocalizedStringFromTable(@"back", nil, nil);
//                self.navigationItem.backBarButtonItem = backBtn;
                //[self.navController pushViewController:libView animated:YES];
                //[self.navController pushViewController:cont animated:YES];
            }
        } else // if file
        {
            playFileName = [m_filesArray objectAtIndex:row];
            
            [self uploadOrPlay:[m_documentDirectory
                                stringByAppendingFormat:
                                @"/%@", [m_filesArray objectAtIndex:row]]];
        }
}







/*
 *  play media
 */
- (void)uploadOrPlay:(NSString *)path {
    LocaFileSelectedViewController *mpViewCtr =
    [[LocaFileSelectedViewController alloc] init];
    [mpViewCtr.filePath setString:path];
    [mpViewCtr.fileName setString:playFileName];
    
    // add images
    mpViewCtr.documentDirectory = [NSString stringWithString:m_documentDirectory];
    
    for (int i = 0; i < [m_filesArray count]; ++i) {
        if ((([[m_filesArray[i] pathExtension] compare:@"jpg"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame) ||
             ([[m_filesArray[i] pathExtension] compare:@"png"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame) ||
             ([[m_filesArray[i] pathExtension] compare:@"bmp"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame) ||
             ([[m_filesArray[i] pathExtension] compare:@"jpeg"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame) ||
             ([[m_filesArray[i] pathExtension] compare:@"ico"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame) ||
             ([[m_filesArray[i] pathExtension] compare:@"gif"
                                               options:NSCaseInsensitiveSearch] ==
              NSOrderedSame))) {
                 [mpViewCtr.photosArray addObject:m_filesArray[i]];
             }
    }
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.navController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navController pushViewController:mpViewCtr animated:NO];
}

//控制tableview的section的显示个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//控制每一个section显示的条数
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [m_filesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //修改远程登录后修改无线设置成功之后刷新没有效果的问题 by lixiang
    NSString *cellID = [NSString stringWithFormat:@"cell%d%d", indexPath.row, indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    //判断当前行的文件类型是文件还是文件夹
    NSUInteger row = [indexPath row];
    NSString *fileName = [m_filesArray objectAtIndex:row];
    NSString *path =
    [m_documentDirectory stringByAppendingFormat:@"/%@", fileName];
    
    BOOL isDir = NO;
    BOOL valid = NO;
    valid =
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (valid)
        if (isDir) {
            cell.imageView.image = [UIImage imageNamed:@"folder.png"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            //列表中显示不同的缩略图 - add by kk
            NSString *nameSuffix = [fileName pathExtension];
            NSPredicate *imgPredicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] 'jpg' || SELF ENDSWITH[cd] 'png' || SELF ENDSWITH[cd] 'bmp' || SELF ENDSWITH[cd] 'jpeg' || SELF ENDSWITH[cd] 'ico' || SELF ENDSWITH[cd] 'gif'"];
            NSPredicate *audioPredicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] 'mp3' || SELF ENDSWITH[cd] 'aac' || SELF ENDSWITH[cd] 'alac' || SELF ENDSWITH[cd] 'm4a'"];
//            if (([nameSuffix compare:@"jpg" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame) ||
//                ([nameSuffix compare:@"png" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame) ||
//                ([nameSuffix compare:@"bmp" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame) ||
//                ([nameSuffix compare:@"jpeg" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame) ||
//                ([nameSuffix compare:@"ico" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame) ||
//                ([nameSuffix compare:@"gif" options:NSCaseInsensitiveSearch] ==
//                 NSOrderedSame)) {
            if ([imgPredicate evaluateWithObject:nameSuffix]) {
                NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
                NSData *imagedata = [[NSData alloc] initWithContentsOfURL:url];
                UIImage *originImage = [[UIImage alloc] initWithData:imagedata];
                UIImage *formatImage =
                [originImage imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
                if (originImage == nil) {
                    cell.imageView.image = [UIImage imageNamed:@"file.png"];
                } else {
                    cell.imageView.image = formatImage;
                }
            } else if (([nameSuffix compare:@"mov" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
                       ([nameSuffix compare:@"mp4" options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                UIImage *originImage;
                originImage = [self getImageFromVideo:path];
                UIImage *formatImage =
                [originImage imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
                if (originImage == nil) {
                    cell.imageView.image = [UIImage imageNamed:@"video.png"];
                } else {
                    cell.imageView.image = formatImage;
                }
//            } else if (([nameSuffix compare:@"mp3" options:NSCaseInsensitiveSearch] ==
//                                 NSOrderedSame) ||
//                                ([nameSuffix compare:@"aac" options:NSCaseInsensitiveSearch] ==
//                                 NSOrderedSame) ||
//                                ([nameSuffix compare:@"alac"
//                                             options:NSCaseInsensitiveSearch] ==
//                                 NSOrderedSame) ||
//                                ([nameSuffix compare:@"m4a" options:NSCaseInsensitiveSearch] ==
//                                 NSOrderedSame)) {
            } else if ([audioPredicate evaluateWithObject:nameSuffix]) {
                UIImage *originImage;
                originImage = [self getImageFromMusic:path];
                UIImage *formatImage =
                [originImage imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
                if (originImage == nil) {
                    cell.imageView.image = [UIImage imageNamed:@"music.png"];
                } else {
                    cell.imageView.image = formatImage;
                }
            } else {
                cell.imageView.image = [UIImage imageNamed:@"file.png"];
            }
            
            NSString *unit;
            CGFloat value;
            unsigned long long size =
            [[m_sizeArray objectAtIndex:row] unsignedLongLongValue];
            if (size < 1024) {
                value = size;
                unit = @"B";
                
            } else if (size < 1048576) {
                value = size / 1024.f;
                unit = @"KB";
                
            } else {
                value = size / 1048576.f;
                unit = @"MB";
            }
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f%@", value, unit];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
    
    //检测系统版本，ios6里使用tintColor会crash
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        cell.tintColor = [UIColor blackColor];
    }
    cell.textLabel.text = fileName;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    if (row == m_rowCurr)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

/*
 *  get screenshots from video
 */
- (UIImage *)getImageFromVideo:(NSString *)videoURL {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:videoURL];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *gen =
    [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(3.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    
    CGImageRef image =
    [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *currentImg = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    return currentImg;
}

/*
 *  get image from mp3
 */
- (UIImage *)getImageFromMusic:(NSString *)musicURL {
    // add by lg
    return nil;
    
    UIImage *retImg;
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:musicURL];
    
    AVURLAsset *mp3Asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        // NSLog(@"format type = %@",format);
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            // NSLog(@"commonKey = %@",metadataItem.commonKey);
            // artwork这个key对应的value里面存的就是封面缩略图，其它key可以取出其它摘要信息，例如title
            // - 标题
            if ([metadataItem.commonKey isEqualToString:@"artwork"]) {
                NSData *data =
                [(NSDictionary *)metadataItem.value objectForKey:@"data"];
                // NSString *mime = [(NSDictionary*)metadataItem.value
                // objectForKey:@"MIME"];
                // NSLog(@"mime = %@, data = %@, image = %@", mime, data, [UIImage
                // imageWithData:data]);
                retImg = [UIImage imageWithData:data];
                
                return retImg;
            }
        }
    }
    retImg = [UIImage imageNamed:@"music.png"];
    return retImg;
}

//添加文件删除功能 - add by kk
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [m_tableView setEditing:editing animated:animated];
}

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    //禁止滑动删除Cell，又允许在编辑状态下进行删除
    if (!tableView.editing)
        return UITableViewCellEditingStyleNone;
    else
        return UITableViewCellEditingStyleDelete;
}

- (void)trashButtonPress {
    if (is_editing == NO) {
        [self setEditing:YES animated:YES];
        is_editing = YES;
    } else {
        [self setEditing:NO animated:YES];
        is_editing = NO;
    }
}

- (NSFileManager *)GetFileManager {
    return m_fileManager;
}
- (NSString *)GetFileNameCurrSel {
    return m_fileName;
}

- (NSString *)GetDir {
    return m_documentDirectory;
}



#pragma mark - DoImagePickerControllerDelegate
- (void)didCancelDoImagePickerController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectPhotosFromDoImagePickerController:(DoImagePickerController *)picker result:(NSArray *)aSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    if (picker.nResultType == DO_PICKER_RESULT_UIIMAGE)
//    {
//        for (int i = 0; i < MIN(4, aSelected.count); i++)
//        {
//            UIImageView *iv = _aIVs[i];
//            iv.image = aSelected[i];
//        }
//    }
//    else if (picker.nResultType == DO_PICKER_RESULT_ASSET)
//    {
//        for (int i = 0; i < MIN(4, aSelected.count); i++)
//        {
//            UIImageView *iv = _aIVs[i];
//            iv.image = [ASSETHELPER getImageFromAsset:aSelected[i] type:ASSET_PHOTO_SCREEN_SIZE];
//        }
//        
//        [ASSETHELPER clearData];
//    }
}



@end
