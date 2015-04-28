
#import "TreeViewController.h"
#import "FileViewController.h"
#import "KxSMBProvider.h"
#import "SDWebImageManager+SMB.h"

//#import "UIImage+UIImageExt.h"
#import "UIAlertViewBlock.h"
#import "smbCollectionView.h"
#import "UIImage+Resize.h"
#import "UIImage+UIImageExt.h"

#import "constStrings.h"
#import "UIPopoverControllerBlock.h"
#import "sheetTableViewController.h"
#import "ipTool.h"
#import "smbCollectionView.h"


@interface TreeViewController () <UITableViewDataSource, UITableViewDelegate  >
@property (nonatomic) BOOL bSelectUpload;
@property (nonatomic, strong) NSString *_urlLocalFileToUpload;
@property (nonatomic,strong) smbCollectionViewController *collectionView;
@property (nonatomic) BOOL isSub;
@end

@implementation TreeViewController {
    NSArray     *_items;
    UIImage    *_fileImage;
    
    NSFileHandle *localFileHandle;
    
    UIBarButtonItem *_moreButton;
    
    BOOL _isScrolling ;
    BOOL _isMemoryLow;
    BOOL _isLoading;
    UIPopoverControllerBlock *_popoverController;
}




#pragma mark - 

-(void)dealloc
{
    _items = nil;
    _fileImage = nil ;
}

- (void) setPath:(NSString *)path
{
    _path = path;
    [self reloadPath];
}

-(instancetype)initSub
{
    self = [super init];
    if (self) {
        
        self.title = @"";
        self.isSub = TRUE;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.title = @"";
    }
    return self;
}

- (id)initAsHeadViewController {
    if((self = [self init])) {
        self.navigationItem.title = @"Remote";
    }
    return self;
}


#pragma mark - new Add

- (instancetype)initAsHeadWithMediaType:(enum MediaType)type
{
    if((self = [self init])) {
        self.navigationItem.title = @"Remote";
        self.mediaType = type;
        self.isSub = false;
        self.path = [RootData shared].path;
    }
    return self;
}


-(instancetype)initSubWithMediaType:(enum MediaType)type
{
    self = [super init];
    if (self) {
        
        self.title = @"";
        self.isSub = TRUE;
        self.mediaType = type;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    if(NSClassFromString(@"UIRefreshControl")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadPath) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
    
    _fileImage = [UIImage imageNamed:@"file.png"];
}

/*
-(void)upoadLocalFile
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"upload confirm", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
    [alert show];
    alert.tag = TAG_LOCALFILE_UPLOADCOMFIRM;
}
*/





- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
//    _moreButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"burger"] landscapeImagePhone:[UIImage imageNamed:@"burger@2x"] style:UIBarButtonItemStylePlain target:self action:@selector(showMenu:)];
    
    if(self.isSub)
    {
        
//        self.navigationItem.rightBarButtonItem = _moreButton;
    }
    else
    {
        
        /*
        UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc] initWithTitle:@"设置IP" style:UIBarButtonItemStyleDone target:self action:@selector(actionReloadPath)];
        
        self.navigationItem.rightBarButtonItem = rightBtn;
        */
        
        
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:[RSHelper shared] action:@selector(requestNewPath)];
        
    }

    /*
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"photo_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(ShowPhotoBroswer)];
    self.navigationItem.rightBarButtonItem.enabled = false;
     */
    
}





- (void)showMenu:(id)sender
{
    if(self.tableView.isEditing)
    {
        [self setEditing:NO animated:YES];
        return;
    }
    
    
    
    if(_isSub)
    {
        
        NSArray *arrObject=@[NSLocalizedString(@"Photo browser",nil),
                             NSLocalizedString(@"Add Folder", nil),
                             NSLocalizedString(@"Delete", nil),
                             NSLocalizedString(@"Refresh",nil)];
        NSArray *arrImage =@[@"photo_icon",
                             @"Icon_newfolder.png",
                             @"Icon_delete.png",
                             @"refresh.png"];
        
        if(!_popoverController)
        _popoverController=[[UIPopoverControllerBlock alloc]initWithObjects:arrObject images:arrImage CallBack:^(UIPopoverControllerBlock *popoverController, int index) {
            [popoverController dismissPopoverAnimated:YES];
            
            if (index == 0)
            {
                [self ShowPhotoBroswer];
            } else if (index == 1)
            {
                [self MenuAdd];
            }
            else if (index == 2)
            {
                [self MenuEdit];
            }
            else if (index == 3)
            {
                [self reloadPath];
            }
            
        }];
        
        
        
        [_popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

-(void)MenuAdd
{
    [self DlgMkDir:nil];
}

-(void)MenuEdit
{
    if(self.editing)
        [self setEditing:NO animated:YES];
    else
        [self setEditing:YES animated:YES];
    
    [self.tableView reloadData];
}


-(void)ShowPhotoBroswer
{
    //collection view need ios 6.
    NSAssert([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0, @"need ios 6.0");
    
    
    NSMutableArray *imageArray = _items;//= [[NSMutableArray alloc]init];
    
    /*
    for (KxSMBItem *smbItem in _items)
    {
        if( [arrayPictureTypes containsObject:[[smbItem.path pathExtension] lowercaseString]] )
        {
            if(smbItem.stat.size > 0  && smbItem.stat.size < 3145728)
            {
                [imageArray addObject:smbItem];
                
            }
        }
    }
     */
    
    if([imageArray count] == 0)
        return;
    
    //弹出模态相册浏览器
    self.collectionView = [[smbCollectionViewController alloc]init];
    self.collectionView.enableCoverFlow = true;
    
    UINavigationController *navgationCtlr;
    navgationCtlr=[[UINavigationController alloc]initWithRootViewController:self.collectionView];
    
    
    [self.collectionView setPhotoImages:imageArray];
    
    self.collectionView.view.autoresizingMask = ~0;
    
    [self.navigationController presentViewController:navgationCtlr animated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning
{
    NSLog(@"tree view didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    
    _isMemoryLow = YES ;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

}




- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}


#pragma  mark -

-(void) reloadPath:(NSString*)ipAdress
{
    NSAssert(NSEqualRanges( [ipAdress rangeOfString:@"smb" ], NSMakeRange(NSNotFound, 0)  ), @"Pass a IP adress!");
    
    self.path=[NSString stringWithFormat:@"smb://%@",ipAdress];
}


-(void)endRefresh
{
    if(NSClassFromString(@"UIRefreshControl"))
        [self.refreshControl endRefreshing];
}



-(void)beginRefresh
{
    if(NSClassFromString(@"UIRefreshControl")) {
        if(![self.refreshControl isRefreshing])
            [self.refreshControl beginRefreshing];
    }
}

- (void)reloadPath
{
    if(!_path)
    {
        [self endRefresh];
        return;
    }
    
    
    if(_isLoading)
        return;
    
    _isLoading = TRUE;
    
    self.tableView.tableHeaderView = nil;
    
    [self beginRefresh];
    
    if (_path.length)
        self.navigationItem.title=_path.lastPathComponent;
    
    _items = nil;
    [self.tableView reloadData];
    

    [self updateStatus:NSLocalizedString(@"Fetching",nil)];
    
    __weak typeof(self) weakSelf = self ;
    KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
    
    [provider fetchAtPath:_path block:^(id result) {
        [weakSelf ParseFetchResult:result];
    }];
}

-(void)ParseFetchResult:(id)result
{
    if ([result isKindOfClass:[NSError class]])
    {
        [self updateStatus:result ];
    } else
    {
        [self updateStatus:nil];
        
        
        if ([result isKindOfClass:[NSArray class]])
        {
            NSArray *arr = (NSArray*)result;
            
            NSMutableArray *filter = [ NSMutableArray array];
            
            for (id item in arr) {
                NSLog(@"%@",item);
                if ([item isKindOfClass:[KxSMBItemFile class]]) {
                    KxSMBItem *it = (KxSMBItem*)item;
                    if(filterPathByMediaType(it.path, self.mediaType) )
                    {
                        [filter addObject: it];
                    }
                }
                else // tree
                {
                    [filter addObject: item];
                }
            }
            
            if(_items)
                _items = [_items arrayByAddingObjectsFromArray:filter];
            else
                _items = filter ;
        } else if ([result isKindOfClass:[KxSMBItem class]]) {
            if(_items)
            {
                KxSMBItem *item = (KxSMBItem*)result;
                if (filterPathByMediaType(item.path, self.mediaType))
                {
                    _items = [_items arrayByAddingObjectsFromArray:@[result]];
                }
            }
            else
            {
                // todo
                assert(false);
                _items = @[result] ;
            }
        }
        
        if(_items.count == 0)
        {
            self.navigationItem.title=NSLocalizedString(@"Folder is Empty",nil);
        }
        else
        {

            [self.tableView reloadData];
            [self.tableView flashScrollIndicators];
        }
        
        
        [self endRefresh];
        

            
        [self updateStatus:nil];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    _isLoading = FALSE;

    
    if( self.mediaType == MediaTypePhoto)
    {
        self.navigationItem.rightBarButtonItem.enabled = true;
    }
}





- (void) updateStatus: (id) status
{
#ifdef DEBUG
    NSAssert([NSThread isMainThread], @"Only update UI from main thread");
#endif
    
    UIFont *font = [UIFont boldSystemFontOfSize:16];
    
    if ([status isKindOfClass:[NSString class]]) {
        
        const float W = self.tableView.frame.size.width;
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, W, font.lineHeight )];
        label.text = status;
        label.font = font;
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.opaque = NO;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.numberOfLines = 2;
        [label sizeToFit];
        
        [self beginRefresh];
        
        
        self.tableView.tableHeaderView = label;
        
        
    } else if ([status isKindOfClass:[NSError class]]) {
        NSError *error = status ;
        const float W = self.tableView.frame.size.width;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, W, font.lineHeight)];
       
            label.text =error.localizedDescription;
        
        label.font = font;
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.opaque = NO;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.numberOfLines = 0;
        [label sizeToFit];
        
        [self endRefresh];
        
        self.tableView.tableHeaderView = label;

    } else {
        
        self.tableView.tableHeaderView = nil;
        
        [self endRefresh];
    }
}



- (void) actionMkDir:(id)folderName
{
    NSString *path = [_path stringByAppendingSMBPathComponent:folderName];
    
    KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
    id result = [provider createFolderAtPath:path];
    if ([result isKindOfClass:[KxSMBItemTree class]]) {
        
        NSMutableArray *ma = [_items mutableCopy];
        [ma addObject:result];
        _items = [ma copy];
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_items.count-1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
    } else
    {
        NSString *msg;
        if(![[result localizedDescription] isEqualToString:@""])
        {
            msg = [result localizedDescription] ;
        }
        else
            msg = NSLocalizedString(@"Unable mkdir" , nil);
        
        [self updateStatus:msg];
        
        
        
        NSLog(@"%@", result);
    }
}



-(void)DlgMkDir:(id)sender
{
    __weak typeof(self) weakSelf = self ;
    UIAlertViewBlock *alert = [[UIAlertViewBlock alloc] initWithTitle:@"Create A Folder"
                                                              message:nil
                                                    cancelButtonTitle:NSLocalizedString(@"cancel",nil) cancelledBlock:^(UIAlertViewBlock *alertView){
                                                        
                                                    } okButtonTitles:NSLocalizedString(@"Create",nil) okBlock:^(UIAlertViewBlock *alertView){
                                                        NSString *folderName=[alertView textFieldAtIndex:0].text;
                                                        [weakSelf actionMkDir:folderName];
                                                    }];
    
    
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].placeholder=@"FolderName";
    [alert textFieldAtIndex:0].text = NSLocalizedString(@"NewFolder",nil) ;
    [alert show];
    [[alert textFieldAtIndex:0] becomeFirstResponder];
}

-(void)updateCellImage:(UITableViewCell *)cell Row:(int)row
{
    if(_isMemoryLow)
        return;
    
    KxSMBItemFile *smbFile = _items[row];
    
    //If is a image file , show it in cell's left .
    if([arrayPictureTypes containsObject:[[smbFile.path pathExtension] lowercaseString]]
       && smbFile.stat.size < 1.2 * 1024 * 1024)
        //小于3M才加载
        //加载图片太大时出错
    {
        //empty size
        if(smbFile.stat.size != 0){
            NSArray *arrayView = [cell.contentView subviews] ;
            UIImageView *imageView = arrayView[0] ;
            
            __block __weak UIImageView *__imageView = imageView ;
            __block __weak UITableViewCell *_weakCell = cell;
            [imageView setImageWithSmbItem:_items[row] placeholderImage:[UIImage imageNamed:@"Placeholder_null"] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if(_weakCell && __imageView){
                    image = [image imageByScalingAndCroppingForSize:CGSizeMake(32, 32)];
                    
                    // image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(32, 32) interpolationQuality:kCGInterpolationLow];
                    [__imageView setImage:image];
                    [__imageView setNeedsLayout];
                    
                }
            } needRefresh:NO];
        }}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellTreeView";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell)
        cell = [[NSBundle mainBundle]loadNibNamed:@"TreeViewControllerCell" owner:self options:nil][0];
    
    
    KxSMBItem *item = _items[indexPath.row];
    
    NSArray *arrayView = [cell.contentView subviews] ;
    UIImageView *imageView = arrayView[0] ;
    UILabel *textLabel = arrayView[1] ;
    UILabel *detailTextLabel = arrayView[2] ;
    
    
    textLabel.text = item.path.lastPathComponent;
    
    //is folder
    if ([item isKindOfClass:[KxSMBItemTree class]]) {
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIImage* image = [UIImage imageNamed:@"folder.png"];
        imageView.image = image;
        
    } else //is file
    {
        KxSMBItemFile *smbFile = (KxSMBItemFile*)item ;
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        NSString *unit;
        CGFloat value;
        unsigned long long size = item.stat.size ;
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
        
        detailTextLabel.text=[NSString stringWithFormat:@"%.1f%@",value,unit];
        
        //If is a image file , show it in cell's left .
        if([arrayPictureTypes containsObject:[[smbFile.path pathExtension] lowercaseString]]
           && smbFile.stat.size < 1.2 * 1024 * 1024)
            //小于3M才加载
            //加载图片太大时出错
        {
            //empty size
            if(smbFile.stat.size == 0)
            {
                imageView.image = [UIImage imageNamed:@"Placeholder_null"];
            }
            else
            {
                if(_isScrolling)
                {
                    imageView.image = [UIImage imageNamed:@"Placeholder_null"];
                }
                else
                {
                    [self updateCellImage:cell Row:indexPath.row];
                }
            }
            
        }
        else if ( [arrayMusicTypes containsObject:[[smbFile.path pathExtension] lowercaseString] ] )
        {
            imageView.image = [UIImage imageNamed:@"music.png"];
        }
        else if ( [arrayMovieTypes containsObject:[[smbFile.path pathExtension] lowercaseString] ] )
        {
            imageView.image = [UIImage imageNamed:@"video.png"];
        }
        else
        {
            imageView.image = _fileImage;
        }
        
    }

    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(NSClassFromString(@"UIRefreshControl")) {
        if(![self.refreshControl isRefreshing])
            self.tableView.tableHeaderView = nil;
    }
    else
        self.tableView.tableHeaderView = nil;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    KxSMBItem *item = _items[indexPath.row];
    if ([item isKindOfClass:[KxSMBItemTree class]]) {
        
        TreeViewController *vc ;

        vc =[[TreeViewController alloc] initSub ];
        
        vc.path = item.path;
        
        vc.mediaType = self.mediaType;
        
//        [RSHelper shared].currRemote=vc;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([item isKindOfClass:[KxSMBItemFile class]]) {

            FileViewController *vc = [[FileViewController alloc] init];
            vc.smbFile = (KxSMBItemFile *)item;
            
            vc.parentVC = self;
        
        
            //[[RSHelper shared].detailMng setDetailViewController:(UIViewController*)vc];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        __weak typeof(self) weakSelf = self ;
        KxSMBItem *item = _items[indexPath.row];
        [[KxSMBProvider sharedSmbProvider] removeAtPath:item.path block:^(id result) {
            
            NSLog(@"completed:%@", result);
            if (![result isKindOfClass:[NSError class]]) {
                [weakSelf reloadPath];
            }
            else
            {
                NSString *msg;
                if(![[result localizedDescription] isEqualToString:@""])
                {
                    msg = [result localizedDescription] ;
                }
                else
                    msg = NSLocalizedString(@"Unable unlink file", nil);
                
                [self updateStatus:msg];
            }
        }];
    }
}


- (void)loadImagesForOnscreenRows
{
    if ([_items count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self updateCellImage:cell Row:indexPath.row];
            
        }
    }
}

#pragma mark - scroll view delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
    _isScrolling = YES;
    
    if (_isLoading == FALSE)
    {
        self.tableView.tableHeaderView = nil;
    }
    
}



// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        _isScrolling = NO;
        [self loadImagesForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isScrolling = NO;
    [self loadImagesForOnscreenRows];
}


//从本地选择文件上传 - add by kk
#pragma mark - local file to upload
-(void)localFile_upload
{
 /*   if (_urlLocalFileToUpload == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"upload failed", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles:nil];
        alert.alertViewStyle = UIAlertViewStyleDefault;
        [alert show];
        
        return;
    }
    
    //检测相同文件
    NSString *fileName;
    NSString *tempName = [_urlLocalFileToUpload lastPathComponent];
    
    if ([tempName hasPrefix:@"temp."]) {
        fileName = [NSString stringWithString:[tempName substringFromIndex:5]];
    }
    else {
        fileName = tempName;
    }

    for (KxSMBItem *item in _items) {
        if ( [item.path.lastPathComponent isEqualToString:fileName] )
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:NSLocalizedString(@"exists file", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
            alert.alertViewStyle = UIAlertViewStyleDefault;
            [alert show];
            alert.tag = TAG_LOCALFILE_OVERWRITE;
            return;
        }
    }
    [self localFile_uploadOverWrite];*/
}

-(void)localFile_uploadOverWrite
{
 /*   NSString *localPath = _urlLocalFileToUpload;
    
    NSString *fileName;
    NSString *tempName = [localPath lastPathComponent];
    
    if ([tempName hasPrefix:@"temp."]) {
        fileName = [NSString stringWithString:[tempName substringFromIndex:5]];
    }
    else {
        fileName = [NSString stringWithString:tempName];
    }
    
    NSString *path = [_path stringByAppendingSMBPathComponent:fileName];
    
    NSError *error;
    localFileHandle = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:localPath] error:&error];
    
    if (!localFileHandle) {
        //NSLog(@"file handle error = %@", error.localizedDescription);
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedStringFromTable(@"upload failed", @"Localizable", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"ok",nil)
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"uploading", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:nil, nil];
    
    //draw circular progress
    MDRadialProgressView *uploadProgress = [self progressViewWithFrame:CGRectMake(0, 0, 50, 50)];
    
    UIProgressView *progressLowVer = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressLowVer.frame = CGRectMake(30, 40, 225, 10);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        [uploadProgress setProgressTotal:100];
        [uploadProgress setProgressCounter:0];
        uploadProgress.theme.sliceDividerHidden = YES;
        [alert setValue:uploadProgress forKey:@"accessoryView"];
    }
    else
    {
        [alert addSubview:progressLowVer];
    }
    [alert show];
    alert.tag = TAG_LOCALFILE_CANCELUPLOAD;
    
    NSDictionary *dictFile = [[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:nil];
    unsigned long long fileSize = [dictFile fileSize];
    __weak typeof(self) weakSelf = self ;
    KxSMBProvider *provider = [KxSMBProvider sharedSmbProvider];
    [provider copyLocalPath:localPath smbPath:path overwrite:YES progress:^(KxSMBItem *item, unsigned long transferred) {
        
        NSLog(@"progress = %ld", transferred);
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            [uploadProgress setProgressCounter:(NSInteger)((float)(transferred) / (float)(fileSize)*100)];
        else
            progressLowVer.progress = (float)(transferred) / (float)(fileSize);
        
    } block:^(id result) {
        
        [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:0];
        
        
        if ([result isKindOfClass:[KxSMBItemFile class]]) {
            
            if (![result isKindOfClass:[NSError class]])
            {
                UIAlertView* alertResult = [[UIAlertView alloc] initWithTitle:nil
                                                                      message:NSLocalizedStringFromTable(@"upload successful", @"Localizable", nil)
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"ok",nil)
                                                            otherButtonTitles:nil, nil];
                [alertResult show];
                alertResult.tag = TAG_RETURN_TO_LOCAL;
                [weakSelf reloadPath];
            }
            else
            {
                UIAlertView* alertResult = [[UIAlertView alloc] initWithTitle:nil
                                                                      message:NSLocalizedStringFromTable(@"upload failed", @"Localizable", nil)
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"ok",nil)
                                                            otherButtonTitles:nil, nil];
                [alertResult show];
                [weakSelf reloadPath];
                
            }
        }
        else {
            NSLog(@"%@", result);
            
            
            NSString *msg = nil;
            
            if(![[result localizedDescription] isEqualToString:@""])
            {
                msg = [result localizedDescription] ;
            }
            else
                msg = NSLocalizedString(@"upload failed" , nil);
            
            
            UIAlertView* alertResult = [[UIAlertView alloc] initWithTitle:nil
                                                                  message:msg
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"ok",nil)
                                                        otherButtonTitles:nil, nil];
            [alertResult show];
            
            
            
            
        }
    }];*/
}

- (void) localFile_closeFiles
{
    if (localFileHandle) {
        
        [localFileHandle closeFile];
        localFileHandle = nil;
    }
    //stop uploading
    [KxSMBProvider setStopUploading:YES];
}

/*
- (MDRadialProgressView *)progressViewWithFrame:(CGRect)frame
{
	MDRadialProgressView *view = [[MDRadialProgressView alloc] initWithFrame:frame];
    
	// Only required in this demo to align vertically the progress views.
	view.center = CGPointMake(self.view.center.x + 80, view.center.y);
	
	return view;
}
*/


@end




