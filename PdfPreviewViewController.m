//
//  PdfPreviewViewController.m
//  GenieiPhoneiPod
//
//  Created by liaogang on 5/21/14.
//
//

#import "PdfPreviewViewController.h"
#import  <QuickLook/QuickLook.h>


#if !__has_feature(objc_arc)
#error PdfPreviewViewController.m is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


@interface PdfPreviewViewController ()
<QLPreviewControllerDataSource, QLPreviewControllerDelegate,QLPreviewItem>
{
    NSArray *_arrDosc;
}
@end

@implementation PdfPreviewViewController

-(id)initWithFilePaths:(NSArray*)paths
{
    self =[super init];
    if (self) {
        NSAssert([paths.firstObject isKindOfClass:[NSURL class]], @"url array.");
        _arrDosc = paths;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    
    
    self.dataSource=self;
    self.delegate=self;
    //[self performSelector:@selector(showDocument) withObject:nil afterDelay:3];
}


-(void)showDocument
{
    [self presentViewController:self animated:YES completion:nil];
}

#pragma mark delegates 

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return [_arrDosc count];
}


-(id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return _arrDosc[index];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
