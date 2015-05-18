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

#import "RootData.h"

#import "BOSImageResizeOperation.h"
#import <CoreData/CoreData.h>
#import "ThreadJob.h"


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
    NSMutableArray *scaledImagePathsThumbnail;
    NSMutableArray *scaledImagePathsScreen;
    
    
    NSInteger _indexSelected;
    
    CCoverflowCollectionViewLayout *_layoutCover;
    UICollectionViewFlowLayout *_layoutNormal;
    
    UICollectionViewController *_collectViewNormal;
    UICollectionViewController *_collectViewCover;
    UICollectionViewController *_collectViewCurr;
    
    CGSize rcImage;
}
@property (nonatomic,strong) NSArray *smbItemFiles;
@end


@implementation smbCollectionViewController

-(void)dealloc
{
    [[SDWebImageManager sharedManager] cancelAll];
}

-(void)didReceiveMemoryWarning
{
//    [self.navigationController dismissViewControllerAnimated:NO completion:nil];

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
    
    
    [self setPhotoImages: [[RootData shared] getDataOfCurrMediaTypeVerifyFiltered]];
    
    
    _indexSelected= -1;
    
    
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
    if (imageArray_.count>0 && [imageArray_.firstObject isKindOfClass:[KxSMBItemFile class]])
    {
        
        _smbItemFiles = imageArray_;
        
        NSUInteger count = _smbItemFiles.count;
        
        scaledImagePathsThumbnail = [NSMutableArray arrayWithCapacity:count ];
        scaledImagePathsScreen = [NSMutableArray arrayWithCapacity:count ];
        
        NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        folder =[folder stringByAppendingPathComponent:@"Downloads"];
        for (int i=0;i<count;++i)
        {
            NSString* t =[folder stringByAppendingPathComponent:[@(i).stringValue stringByAppendingString:@"-thumbnail"] ];
            t =[t stringByAppendingPathExtension:@"png"];
            
            NSString* s =[folder stringByAppendingPathComponent:[@(i).stringValue stringByAppendingString:@"-screen"] ];
            s =[s stringByAppendingPathExtension:@"png"];
            
            [scaledImagePathsThumbnail addObject: t];
            [scaledImagePathsScreen addObject: s];
        }
        
        
        self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"%d pictures",nil),[_smbItemFiles count] ];
        
    }
}


- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section;
{
    return [_smbItemFiles  count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    Cell2 *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    
    KxSMBItemFile *smbItem = _smbItemFiles [indexPath.row];
    
    __block __weak Cell2 *_weakCell = (Cell2*)cell;
    
    cell.label.text =  smbItem.path.lastPathComponent;
    
//    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
//                                                            NSUserDomainMask,
//                                                            YES) lastObject];
//    
//    
//    folder =[folder stringByAppendingPathComponent:@"Downloads"];
//    
//    folder =[folder stringByAppendingPathComponent:@(indexPath.row).stringValue];
//    cell.imageV.image = [[UIImage alloc]initWithContentsOfFile: folder];
//    return cell;
    
    //is scaledimage cached?
//    UIImage *scaledImage = scaledImages[indexPath.row];
    
//    [[NSAttributeDescription alloc] setAllowsExternalBinaryDataStorage:YES];
    
//    if( [scaledImage isKindOfClass:[UIImage class]])
//        [cell.imageV setImage:scaledImage ];
//    else
    {
//        if ([scaledImagePaths isKindOfClass:[NSString class]]) {
//            cell.imageV.image = [[UIImage alloc]initWithContentsOfFile:scaledImagePaths[indexPath.row]];
//        }
//        else
        {
//            NSString *systemVersion = [UIDevice currentDevice].systemVersion;
//            if([systemVersion intValue] < 8.0 )
//            {
                [self prepareCell:cell forItemAtIndexPath:indexPath];
//            }
        }
    }
    
    return cell;
}

//- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    Cell2 *cell2 = (Cell2*)cell;
//    cell2.imageV.image = nil;
////    cell2.imageFilePath = scaledImagePaths[indexPath.row];
//}


-(void)prepareCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    KxSMBItemFile *smbItem = _smbItemFiles [row];
    __block __weak Cell2 *_weakCell = (Cell2*)cell;
    
    NSLog(@"start download: %@",smbItem);
    
    NSString *pathThumbnail = scaledImagePathsThumbnail[row];
    NSString *pathScreen = scaledImagePathsScreen[row];
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:pathThumbnail])
    {
    __block KxSMBItemFile *weakSmbItem = smbItem;
    
    dojobInBkgnd(^{
        id result = [weakSmbItem readDataToEndOfFile];
        if ([result isKindOfClass:[NSData class]])
        {
            NSData *data = result;
            
            if (data.length == 0)
            {
            } else
            {
                // Download Finished.
                UIImage *image = [[UIImage alloc]initWithData:data];
                image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:_weakCell.imageV.bounds.size interpolationQuality:kCGInterpolationMedium];
                
                
                UIImage *imageScreen = image;
                CGSize rcScr = [UIScreen mainScreen].bounds.size;
                if (image.size.height + image.size.width > 1024. + 1024. )
                {
                    imageScreen = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:rcScr interpolationQuality:kCGInterpolationMedium];
                }
                
                [UIImagePNGRepresentation(image) writeToFile:pathThumbnail atomically:YES];
                [UIImagePNGRepresentation(imageScreen) writeToFile:pathScreen atomically:YES];
            }
        }
    }, ^{
       
//        UIImage *image =  [UIImage imageWithContentsOfFile:folder];
//        _weakCell.imageV.image = image;
    });
    }else
    {
        UIImage *image =  [[UIImage alloc ]initWithContentsOfFile:pathThumbnail];
        _weakCell.imageV.image = image;
        rcImage = _weakCell.imageV.bounds.size;
        
    }
    
    return;
    /*
    
    if (smbItem.stat.size < 12 * 1024 * 1024)
    
    [_weakCell.imageV  setImageWithSmbFile:smbItem placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if(_weakCell )
        {
            if (image)
            {
                NSLog(@"%@",image);
                
                if (image)
                {
                    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                            NSUserDomainMask,
                                                                            YES) lastObject];
                    
                    
                    folder =[folder stringByAppendingPathComponent:@"Downloads"];
                    
                    folder =[folder stringByAppendingPathComponent:@(row).stringValue];
                    
                    
                    //image = [image imageByScalingAndCroppingForSize:_weakCell.imageV.bounds.size];
                    CGSize rcScr = [UIScreen mainScreen].bounds.size;
                    rcScr.width = 100;
                    rcScr.height = 100;
                    if (image.size.height + image.size.width > rcScr.width + rcScr.height)
                    {
                        BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
                        [op resizeToFitWithinSize: rcScr];
                        [op cropToAspectRatioWidth:rcScr.width height:rcScr.height];

                        
                        [op writeResultToPath: folder];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [op start];
                            scaledImagePaths[row] = folder;
                            
                            
                            UIImage* smallerImage = [[UIImage alloc]initWithContentsOfFile:folder];
                            if (smallerImage) {
                                //cache it.
                                //scaledImages[indexPath.row]=smallerImage;
//                                [_weakCell.imageV setImage:smallerImage];
//                                [_weakCell.imageV setNeedsLayout];
                                rcImage = _weakCell.imageV.bounds.size;
                                
                            }
                            
                            
                        });
                    }
                    else
                    {
                        image = [image  resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:_weakCell.imageV.bounds.size interpolationQuality:kCGInterpolationMedium];
                        
                        //cache it.
                        //scaledImages[indexPath.row]=image;
                        
                        [UIImagePNGRepresentation(image) writeToFile:folder atomically:YES];
                        
//                        _weakCell.imageV.image = [[UIImage alloc]initWithContentsOfFile:folder];
//                        [_weakCell.imageV setNeedsLayout];
//                        rcImage = _weakCell.imageV.bounds.size;
                    }
                }
                else
                {
                    NSLog(@"ResizedImageWithContentMode failed.");
                }
            }
        }
    } needRefresh:NO];
*/
    
}



- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(8_0)
{
//    [self prepareCell:cell forItemAtIndexPath:indexPath];
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
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _indexSelected = -1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(_collectViewCurr != _collectViewNormal)
        return;
    
    NSIndexPath *selectedIndexPath = [[collectionView indexPathsForSelectedItems] objectAtIndex:0];

    
    // 直接弹出全屏
    // clicked on the selected item.
    {
        int indexDisplay = selectedIndexPath.row;
        
        _indexSelected = -1 ;
        
        
        // 1.封装图片数据
        if(!photos){
            photos = [NSMutableArray arrayWithCapacity: [_smbItemFiles count] ];
            for (int i = 0; i < [_smbItemFiles count]; i++)
            {
                MJPhoto *photo = [[MJPhoto alloc] init];
                
//                photo.smbItem = _smbItemFiles[i];
                
                photo.filePath = scaledImagePathsScreen[i];
                
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
            
            rc.size = rcImage;
            
            photo.srcImageFrame = rc;
        }
        
        // 2.显示相册
        MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
        browser.currentPhotoIndex = indexDisplay; // 弹出相册时显示的第一张图片是？
        browser.photos = photos; // 设置所有的图片
        [browser show:self.navigationController];
    }
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
