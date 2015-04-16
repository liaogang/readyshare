/*
     File: Cell.m
 Abstract: Custom collection view cell for image and its label.
 */

#import "Cell2.h"
#import "CustomCellBackground.h"


#if !__has_feature(objc_arc)
#error Cell2 is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif


@implementation Cell2

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // change to our custom selected background view
        CustomCellBackground *backgroundView = [[CustomCellBackground alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView = backgroundView;
        self.imageV.contentMode= UIViewContentModeScaleAspectFit;
        
        self.autoresizingMask = ~0;
    }
    return self;
}


@end
