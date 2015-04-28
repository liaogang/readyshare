//
//  bookViewController.m
//  ReadySHAREDemo
//
//  Created by liaogang on 15/4/28.
//  Copyright (c) 2015年 com.uPlayer. All rights reserved.
//

#import "bookViewController.h"
#import "bookCollectionViewCell.h"
#import "RootData.h"
#import "PdfPreviewViewController.h"
#import "UIAlertViewBlock.h"




@interface bookViewController ()
@property (nonatomic,strong) NSArray *files;// KxSMBItemFile
@end

@implementation bookViewController

static NSString * const reuseIdentifier = @"bookCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    self.files = [[RootData shared]getDataOfCurrMediaTypeVerifyFiltered];
    
    
    
    
    
    // Do any additional setup after loading the view.
}

-(int)itemPerLine
{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    
    int itemPerLine = self.view.bounds.size.width / layout.itemSize.width;
    
    return itemPerLine;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1 + self.files.count / [self itemPerLine];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    int itemPerLine = [self itemPerLine];
    int sections = (self.files.count / itemPerLine ) + 1;
    int left = self.files.count - (sections - 1)  * itemPerLine ;
    
    if ( section + 1 == sections )
        return left;
    else
        return itemPerLine;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    bookCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    KxSMBItemFile *file = self.files[indexPath.row];
    
    cell.title.text = [file.path.lastPathComponent stringByDeletingPathExtension];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    KxSMBItemFile *file = self.files[indexPath.row];
    

    
    BOOL e = false;
    
    [[RootData shared]smbFileExistsAtCache:file :&e ];
    
    [[RootData shared] getSmbFileCached:file callback:^(id result)
    {
        if ([result isKindOfClass:[NSString class]])
        {
            NSString *localFilePath = result;
            
            if ([PdfPreviewViewController canPreviewItem:[NSURL fileURLWithPath: localFilePath]])
            {
                PdfPreviewViewController *pdf =[[PdfPreviewViewController alloc]initWithFilePaths:@[[NSURL fileURLWithPath: localFilePath]]];
                
                [self.navigationController pushViewController:pdf animated:YES];
            }
            
        }
        else
        {
            NSError *error = result;
            NSString *shortName = [file.path.lastPathComponent stringByDeletingPathExtension];
            [[[UIAlertViewBlock alloc]initWithTitle: [NSString stringWithFormat: NSLocalizedString(@"Error downloading file: %@", nil) , shortName] message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        }
    }];
    

}



/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
   UICollectionReusableView* view =  [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"bookFooter" forIndexPath:indexPath];
    
    return view;
}
@end
