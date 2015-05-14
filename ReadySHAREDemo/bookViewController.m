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

#import "ReaderViewController.h"


@interface bookViewController ()<ReaderViewControllerDelegate>
@property (nonatomic,strong) NSArray *files;// KxSMBItemFile

@property (nonatomic,assign) int itemPerLine,
    sections, // 排满的行数
    left;

@property (nonatomic,assign) BOOL isLoading;
@end

@implementation bookViewController

static NSString * const reuseIdentifier = @"bookCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.files = [[RootData shared]getDataOfCurrMediaTypeVerifyFiltered];
}

-(int)calcItemPerLine
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
    
    int count = self.files.count;
    self.itemPerLine = [self calcItemPerLine];
    self.sections = (count / self.itemPerLine ) ;
    self.left = count - self.sections  * self.itemPerLine ;
    
    
    
    [self.collectionViewLayout invalidateLayout];

    if (self.files.count == 0) {
        return 0;
    }
    
    return self.sections + (self.left == 0 ? 0 : 1);
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ( section == self.sections )
        return self.left;
    else
        return self.itemPerLine;
}

-(int)indexFromIndexPath:(NSIndexPath*)indexPath
{
    return indexPath.row + indexPath.section * self.itemPerLine;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    bookCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    int index = [self indexFromIndexPath:indexPath];
    
    KxSMBItemFile *file = self.files[index];
    
    cell.title.text = [file.path.lastPathComponent stringByDeletingPathExtension];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoading == true) {
        return;
    }
    
    
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    KxSMBItemFile *file = self.files[[self indexFromIndexPath:indexPath]];
    
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    av.center=self.view.center;
    av.autoresizingMask = ~0;
    [av startAnimating];
    [self.view addSubview:av];
    

    
    self.isLoading = true;
    
    NSLog(@"start Loading.");
    __weak typeof (self) weakSelf = self;
    __weak typeof (av) weakAv = av;
    [[RootData shared] getSmbFileCached:file callback:^(id result)
     {
         NSLog(@"stop Loading.");
         
         if (weakSelf)
         {
             weakSelf.isLoading = false;
             
             [weakAv stopAnimating];
             [weakAv removeFromSuperview];
             
             
             if ([result isKindOfClass:[NSString class]])
             {
                 NSString *localFilePath = result;
                 
                 
                 // Pdf ? txt,doc ?
                 if ([localFilePath.lastPathComponent.pathExtension.lowercaseString isEqualToString:@"pdf"])
                 {
                     NSString *phrase = nil; // Document password (for unlocking most encrypted PDF files)
                     
                     ReaderDocument *document = [ReaderDocument withDocumentFilePath:localFilePath password:phrase];
                     
                     if (document != nil) // Must have a valid ReaderDocument object in order to proceed with things
                     {
                         ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
                         
                         readerViewController.delegate = weakSelf; // Set the ReaderViewCont`roller delegate to self
                         
#if (DEMO_VIEW_CONTROLLER_PUSH == TRUE)
                         
                         [self.navigationController pushViewController:readerViewController animated:YES];
                         
#else // present in a modal view controller
                         
                         readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                         readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
                         
                         [weakSelf presentViewController:readerViewController animated:YES completion:NULL];
                         
#endif // DEMO_VIEW_CONTROLLER_PUSH
                     }
                     else // Log an error so that we know that something went wrong
                     {
                         //                NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, filePath, phrase);
                     }
                     
                 }
                 else
                 {
                     if ([PdfPreviewViewController canPreviewItem:[NSURL fileURLWithPath: localFilePath]])
                     {
                         PdfPreviewViewController *pdf =[[PdfPreviewViewController alloc]initWithFilePaths:@[[NSURL fileURLWithPath: localFilePath]]];
                         pdf.currentPreviewItemIndex = 3;
                         [weakSelf.navigationController pushViewController:pdf animated:YES];
                     }
                 }
                 
                 
                 
                 
             }
             else
             {
                 NSError *error = result;
                 NSString *shortName = [file.path.lastPathComponent stringByDeletingPathExtension];
                 [[[UIAlertViewBlock alloc]initWithTitle: [NSString stringWithFormat: NSLocalizedString(@"Error downloading file: %@", nil) , shortName] message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             }
         }
     }];
    

}

#pragma mark - ReaderViewControllerDelegate methods

- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
#if (DEMO_VIEW_CONTROLLER_PUSH == TRUE)
    
    [self.navigationController popViewControllerAnimated:YES];
    
#else // dismiss the modal view controller
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
#endif // DEMO_VIEW_CONTROLLER_PUSH
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
