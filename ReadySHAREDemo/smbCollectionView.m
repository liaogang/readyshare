//
//  smbCollectionView.m
//  GenieiPhoneiPod
//
//  Created by liaogang on 4/10/14.
//
//
#import "smbCollectionView.h"
#import "KxSMBProvider.h"
#import "Cell2.h"
#import "SDWebImageManager+SMB.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"
#import "UIAlertViewBlock.h"
#import "UIImage+Resize.h"

#import "CCoverflowCollectionViewLayout.h"



#if !__has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

NSString *kCellID = @"cellID";


CGSize szNormalIpad = {220.0, 266.0};//{199.0, 266.0};
CGSize szNormalIphone ={138.0, 120.0};

CGSize szCoverIpad ={393. , 537.};
//CGSize szCoverIpad ={420.,430.};
CGSize szCoverIphone ={260.,300.};




@interface smbCollectionViewController ()
<UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSMutableArray *photos;
    NSMutableArray *scaledImages;
    NSInteger _indexSelected;
    
    UIBarButtonItem * _rightBarSave;
    UIBarButtonItem * _rightBarChange;
    
    CCoverflowCollectionViewLayout *_layoutCover;
    UICollectionViewFlowLayout *_layoutNormal;
    
    UICollectionViewController *_collectViewNormal;
    UICollectionViewController *_collectViewCover;
    UICollectionViewController *_collectViewCurr;
}
@property (nonatomic,strong) NSArray *smbItemFiles;
@end


@implementation smbCollectionViewController

-(void)didReceiveMemoryWarning
{
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];

    [super didReceiveMemoryWarning];
    
    [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Photo browser is quited",nil) message:NSLocalizedString(@"Current app received memory warning",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok", nil),nil] show];
}



-(id)init
{
    self=[super init];
//    if (self) {
//    }
    
    return self;
}



-(void)changeFlow
{
    BOOL isCover = _collectViewCurr == _collectViewCover;
    _collectViewCurr = isCover ? _collectViewNormal : _collectViewCover;

    
    [UIView beginAnimations:@"animationID" context:nil];
    
    [UIView setAnimationDuration:0.5f];
    //动画速度
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    //动画方式
    [UIView setAnimationTransition:isCover?UIViewAnimationTransitionFlipFromLeft:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    [UIView setAnimationRepeatAutoreverses:NO];
    
    [self.view bringSubviewToFront:_collectViewCurr.view];
    
    [UIView commitAnimations];
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _indexSelected= -1;
    
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.navigationController action:@selector(dismissModalViewControllerAnimated:)];

    
    bool isIPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    
    CGRect rc = self.view.bounds;
    
    if(_enableCoverFlow)
    {
        _layoutCover =[[CCoverflowCollectionViewLayout alloc]init];
        if( isIPad )
            _layoutCover.cellSize = szCoverIpad;
        else
            _layoutCover.cellSize = szCoverIphone;
        
        _collectViewCover =  [[UICollectionViewController alloc]initWithCollectionViewLayout:_layoutCover];
        [_collectViewCover.collectionView registerNib:[UINib nibWithNibName:@"cover_cell2_iPad" bundle:nil] forCellWithReuseIdentifier:kCellID];
        _collectViewCover.collectionView.delegate =self ;
        _collectViewCover.collectionView.dataSource=self;
        [_collectViewCover.view setFrame: rc];
        _collectViewCover.view.autoresizingMask = ~0 & ~UIViewAutoresizingFlexibleBottomMargin;
        
        [self.view addSubview:_collectViewCover.view];
        
        _rightBarChange = [[UIBarButtonItem alloc]initWithTitle:@"Change" style:UIBarButtonItemStylePlain target:self action:@selector(changeFlow)];
        self.navigationItem.rightBarButtonItem = _rightBarChange;
    }
    
    NSString * cellxibname;

    
    if( isIPad )
        cellxibname = @"cell2_iPad";
    else
        cellxibname = @"cell2";
    
    _layoutNormal=[[UICollectionViewFlowLayout alloc]init];
    _collectViewNormal = [[UICollectionViewController alloc]initWithCollectionViewLayout:_layoutNormal];
    [_collectViewNormal.collectionView registerNib:[UINib nibWithNibName:cellxibname bundle:nil] forCellWithReuseIdentifier:kCellID];
    _collectViewNormal.collectionView.delegate =self ;
    _collectViewNormal.collectionView.dataSource=self;
    [_collectViewNormal.view setFrame: rc];
    [self.view addSubview:_collectViewNormal.view];

    
    _collectViewCurr =_collectViewNormal;
}


-(void)setPhotoImages:(NSArray*)imageArray_
{
    NSAssert(imageArray_.count>0, @"empty array.");
    NSAssert([[imageArray_ firstObject]isKindOfClass:[KxSMBItemFile class]], @"pass a KxSMBItemFile array");
    
    _smbItemFiles = imageArray_;
    
    NSUInteger count = _smbItemFiles.count;
    
    scaledImages = [NSMutableArray arrayWithCapacity:count ];
    
    
    
    for (int i=0;i<count;++i)
    {
        [scaledImages addObject:[NSNull null]];
    }
    
    
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"%d pictures",nil),[_smbItemFiles count] ];
}


- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return [_smbItemFiles  count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    Cell2 *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    
    KxSMBItemFile *smbItem = _smbItemFiles [indexPath.row];
    
    cell.label.text =  smbItem.path.lastPathComponent;
    
    
    //is scaledimage cached?
    UIImage *scaledImage = scaledImages[indexPath.row];
    if( [scaledImage isKindOfClass:[UIImage class]])
    {
        [cell.imageV setImage:scaledImage ];
    }
    else
    {
    __block __weak Cell2 *_weakCell = cell;

    [cell.imageV  setImageWithSmbFile:smbItem placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if(_weakCell )
        {
            if (image)
            {
                NSLog(@"%@",image);
                
                image = [image  resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:_weakCell.imageV.bounds.size interpolationQuality:kCGInterpolationMedium];
                
                if (image)
                {
                    //image = [image imageByScalingAndCroppingForSize:_weakCell.imageV.bounds.size];
                    
                    //cache it.
                    scaledImages[indexPath.row]=image;
                    [_weakCell.imageV setImage:image];
                    [_weakCell.imageV setNeedsLayout];
                }
                else
                {
                    NSLog(@"ResizedImageWithContentMode failed.");
                }
            }
        }
    } needRefresh:NO];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
#ifdef __GENIE_IPHONE__
    if(_collectViewCurr == _collectViewCover)
        return szCoverIphone;
    else
        return szNormalIphone;
#else
    if(_collectViewCurr == _collectViewCover)
        return szCoverIpad;
    else
        return szNormalIpad;
#endif
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return  UIEdgeInsetsMake(6.0, 6.0, 6.0, 6.0);
}

// the user tapped a collection item, load and set the image on the detail view controller
//
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self ShowRightBar:NO];
    
    _indexSelected = -1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(_collectViewCurr != _collectViewNormal)
        return;
    
    NSIndexPath *selectedIndexPath = [[collectionView indexPathsForSelectedItems] objectAtIndex:0];

    
    
    //点击没有选中的项，选中项目，显示菜单
    //点击已选中的项才弹出全屏相册
    if(_indexSelected != selectedIndexPath.row)
    {
        _indexSelected = selectedIndexPath.row;
        
        //show download menu.
        [self ShowRightBar:YES];

        return;
    }
    else//clicked on the selected item.
    {
        int indexDisplay = selectedIndexPath.row;
        
        
        //clear all selection when large photo viewer will display
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        _indexSelected = -1 ;
        //show download menu.
        [self ShowRightBar:NO];
        
        
        
        // 1.封装图片数据
        if(!photos){
            photos = [NSMutableArray arrayWithCapacity: [_smbItemFiles count] ];
            for (int i = 0; i < [_smbItemFiles count]; i++)
            {
                MJPhoto *photo = [[MJPhoto alloc] init];
                
                photo.smbItem = _smbItemFiles[i];
                
                Cell2 *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                
                UIImageView * imageView = cell.imageV;
                
                
                imageView.clipsToBounds = YES;
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.userInteractionEnabled = YES;
                
                photo.srcParentView = self.view;
                [photos addObject:photo];
            }
        }
        
        
        for (int i=0; i <[_smbItemFiles count]; ++i)
        {
            Cell2 *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            
            MJPhoto *photo = photos[i];
            
            CGFloat ox = 0 - _collectViewCurr.collectionView.contentOffset.x;
            CGFloat oy = 0 - _collectViewCurr.collectionView.contentOffset.y;
            
            CGRect rc = CGRectOffset( cell.frame, ox ,oy );
            
            rc = [self.view convertRect:rc toView:self.navigationController.view];
            
            rc = CGRectOffset(rc, cell.imageV.frame.origin.x, cell.imageV.frame.origin.y);
            
            rc.size = cell.imageV.frame.size;
            
            photo.srcImageFrame = rc;
        }
        
        
        
        
        // 2.显示相册
        MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
        browser.currentPhotoIndex = indexDisplay; // 弹出相册时显示的第一张图片是？
        browser.photos = photos; // 设置所有的图片
        [browser show:self.navigationController];
    }
}




-(void)ShowRightBar:(BOOL)bShow
{
    if(!_rightBarSave)
    {
        _rightBarSave = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(Save2Local)];
    
        if(!_rightBarChange)
            _rightBarChange = [[UIBarButtonItem alloc]initWithTitle:@"Change" style:UIBarButtonItemStylePlain target:self action:@selector(changeFlow)];
    }
    
    if(_enableCoverFlow)
        self.navigationItem.rightBarButtonItems = @[_rightBarChange,_rightBarSave];
    else
        self.navigationItem.rightBarButtonItem = bShow ? _rightBarSave : nil ;
    
}

-(BOOL)Save2Local
{
    NSAssert(_indexSelected != -1, @"failed to save to local , selected nothing.");
    
    KxSMBItemFile *smbItem = _smbItemFiles[_indexSelected];
    
    return [self Save2Local:smbItem];
}


//save smbItem to local .
-(BOOL)Save2Local:(KxSMBItemFile*)_smbFile
{
    
    NSFileManager *fm =[[NSFileManager alloc]init];
    
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES) lastObject];
    folder =[folder stringByAppendingPathComponent:@"Downloads"] ;
    
    //确认downloads目录存在。
    [fm createDirectoryAtURL:[NSURL fileURLWithPath:folder]
 withIntermediateDirectories:YES attributes:nil error:nil ];
    
    NSString *filename = _smbFile.path.lastPathComponent;
    
    __block NSString *path2 = [folder stringByAppendingPathComponent:filename];
    
    
    //是否存在相同文件?
    if([fm fileExistsAtPath:path2])
    {
        __weak typeof(self) weakSelf = self ;
        UIAlertViewBlock *alert = [[UIAlertViewBlock alloc] initWithTitle:NSLocalizedString(@"exists file", nil)
                                                                  message:nil
                                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil) cancelledBlock:^(UIAlertViewBlock *alert){
                                                        }
                                                           okButtonTitles:NSLocalizedString(@"ok", nil) okBlock:^(UIAlertViewBlock *alert){
                                                               [[NSFileManager defaultManager] removeItemAtPath:path2 error:nil];
                                                               
                                                               [weakSelf SaveSmbFile:_smbFile toLocal:path2];
                                                               
                                                           }];
        
        
        [alert show];
    }
    else
        [self SaveSmbFile:_smbFile toLocal:path2];
    
    return  YES;
}



-(void)SaveSmbFile:(KxSMBItemFile*)_smbFile  toLocal:(NSString*)path2
{
#ifdef DEBUG
    NSLog(@"Save File From :%@ to :%@",_smbFile.path,path2);
#endif

    NSString *title;

    id result =   [_smbFile readDataToEndOfFile];

    if ([result isKindOfClass:[NSError class]])
    {
        title = [result description] ;
    }
    else if ([result isKindOfClass:[NSData class]])
    {
        NSData *data = result;
        
        if(data.length != _smbFile.stat.size)
        {
            title = @"Download Failed.";
        }
        else  //Download Finished.
        {
            NSError *error = [[NSError alloc]init];
            
            [[NSFileManager defaultManager] createFileAtPath:path2 contents:nil attributes:nil];
            
            NSFileHandle *_fileHandle = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:path2]
                                                            error:&error];
            if(_fileHandle){
            [_fileHandle writeData:result];
            [_fileHandle closeFile];
            _fileHandle = nil;
                
                NSArray *pathComponents =path2.pathComponents;
                
                title = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"File Saved to :",nil),pathComponents[pathComponents.count-2]];
            }
            else
            {
                NSLog(@"%@",error);
                title = [error description];
            }

        }
        
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"refreshLocalViewer" object:nil];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
    [alert show];
    
}









//cell的最小行间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

//cell的最小列间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

@end
