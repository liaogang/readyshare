//
//  PdfPreviewViewController.h
//  GenieiPhoneiPod
//
//  Created by liaogang on 5/21/14.
//
//

#import <QuickLook/QuickLook.h>

@interface PdfPreviewViewController : QLPreviewController
-(id)initWithFilePaths:(NSArray*)paths;
@end
