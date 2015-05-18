/*
     File: Cell.h
 Abstract: Custom collection view cell for image and its label.
 */

#import <UIKit/UIKit.h>

@interface Cell2 : UICollectionViewCell

@property (retain, nonatomic) IBOutlet UIImageView *imageV;
@property (retain, nonatomic) IBOutlet UILabel *label;

@property (strong,nonatomic) NSString *imageFilePath;

@end
