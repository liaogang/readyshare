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
    
    
    
    self.files = [[RootData shared]getDataOfCurrMediaTypeVerifyFiltered];
}

-(int)itemPerLine
{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    
    
    int s = layout.itemSize.width + layout.minimumInteritemSpacing;
    
    
    int itemPerLine = (self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing) / s;
    
    
    return itemPerLine;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    [self.collectionViewLayout invalidateLayout];

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
    
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc]init];
    av.center=self.view.center;
    [av startAnimating];
    [self.view addSubview:av];
    
    [[RootData shared] getSmbFileCached:file callback:^(id result)
    {
        [av stopAnimating];
        [av removeFromSuperview];
        
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



- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
   UICollectionReusableView* view =  [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"bookFooter" forIndexPath:indexPath];
    
    return view;
}
@end
