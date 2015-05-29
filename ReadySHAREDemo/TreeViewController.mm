
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
        
        self.navigationItem.title = NSLocalizedString(@"Movie", nil);
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






- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _items = [[RootData shared]getDataOfCurrMediaTypeVerifyFiltered];
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
    
    
    imageView.image = [UIImage imageNamed:@"video.png"];
    
    
    
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
    if ([item isKindOfClass:[KxSMBItemFile class]])
    {
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FileViewController *vc = [sb instantiateViewControllerWithIdentifier:@"fileViewVCID"];
        vc.smbFile = (KxSMBItemFile *)item;
        vc.parentVC = self;
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

- (void) localFile_closeFiles
{
    if (localFileHandle) {
        
        [localFileHandle closeFile];
        localFileHandle = nil;
    }
    //stop uploading
    [KxSMBProvider setStopUploading:YES];
}


@end




