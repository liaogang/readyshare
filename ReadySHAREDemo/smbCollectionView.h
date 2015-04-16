//
//  smbCollectionView.h
//  GenieiPhoneiPod
//
//  Created by liaogang on 4/10/14.
//
//

#import <UIKit/UIKit.h>

@interface smbCollectionViewController : UIViewController
-(void)setPhotoImages:(NSArray*)imageArray;
@property (nonatomic,assign) BOOL enableCoverFlow;
@end
