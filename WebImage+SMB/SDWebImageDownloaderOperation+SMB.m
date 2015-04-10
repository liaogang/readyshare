/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation+SMB.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import "KxSMBProvider.h"
#import <ImageIO/ImageIO.h>

@interface SDWebImageDownloaderOperation_SMB ()

@property (copy, nonatomic) SDWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) void (^cancelBlock)();

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (assign, nonatomic) NSInteger expectedSize;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, atomic) NSThread *thread;

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@end

@implementation SDWebImageDownloaderOperation_SMB
{
    size_t width, height;
    UIImageOrientation orientation;
    BOOL responseFromCached;
    long _downloadedBytes;
}
@synthesize executing=_executing;
@synthesize finished=_finished;

@synthesize smbItem;

- (id)initWithSmbItem:(KxSMBItemFile *)smbItem_
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)())cancelBlock
{
    if ((self = [super init])) {
#ifdef DEBUG
        NSAssert([smbItem_ isKindOfClass:[KxSMBItemFile class]], @"smbItem is not \"kxsmbitemfile\" class ");
#endif
        self.smbItem = smbItem_ ;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        responseFromCached = YES; // Initially wrong until `connection:willCacheResponse:` is called or not called
    }
    return self;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        if ([self shouldContinueWhenAppEntersBackground]) {
            __weak __typeof__ (self) wself = self;
            self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof (wself) sself = wself;

                if (sself) {
                    [sself cancel];

                    [[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskId];
                    sself.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
        }
#endif

        self.executing = YES;
        self.thread = [NSThread currentThread];
    }

    self.imageData = [[NSMutableData alloc] initWithCapacity:smbItem.stat.size];

    
    if (self.progressBlock) {
        self.progressBlock(0, smbItem.stat.size);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_5_1) {
        // Make sure to run the runloop in our background thread so it can process downloaded data
        // Note: we use a timeout to work around an issue with NSURLConnection cancel under iOS 5
        //       not waking up the runloop, leading to dead threads (see https://github.com/rs/SDWebImage/issues/466)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, false);
    }
    else {
        CFRunLoopRun();
    }

    
    [self DownLoadSmbFile];
    
    
    
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
#endif
}


//Download a Block
-(void)DownLoadSmbFile
{

    __weak __typeof(self) weakSelf = self;
    
    if(!smbItem)
        return;
    id result =   [self.smbItem readDataToEndOfFile];
    if(!weakSelf && weakSelf.finished)
    return ;
    
    @synchronized (smbItem) {

    if ([result isKindOfClass:[NSError class]])
    {
        [self smbConnection:smbItem didFailWithError:result];
    }
    else if ([result isKindOfClass:[NSData class]])
    {
        NSData *data = result;

        if (data.length == 0)
        {
            [self smbConnectionDidFinishLoading];
            [self setFinished:YES];

        } else
        {
            _downloadedBytes = data.length;

        if(_downloadedBytes != smbItem.stat.size)
        {
            [self smbConnection:smbItem didFailWithError:result];
        }
        else  //Download Finished.
        {
            [self smb:smbItem didReceiveData:result];
            [self smbConnectionDidFinishLoading];
            [self setFinished:YES];
        }
    }
    }
        
     }

}


- (void)cancel {
    @synchronized (self) {
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
        else {
            [self cancelInternal];
        }
    }
}

- (void)cancelInternalAndStop {
    [self cancelInternal];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    if (self.cancelBlock) self.cancelBlock();

    self.smbItem=nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];

    // As we cancelled the connection, its callback won't be called and thus won't
    // maintain the isFinished and isExecuting flags.
    if (self.isExecuting) self.executing = NO;
    if (!self.isFinished) self.finished = YES;
    

    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    
    [self reset];
}

- (void)reset {
    [smbItem close];
    smbItem=nil;
    self.cancelBlock = nil;
    self.completedBlock = nil;
    self.progressBlock = nil;
    self.imageData = nil;
    self.thread = nil;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}



- (void)smb:(KxSMBItemFile *)smbItem didReceiveData:(NSData *)data {
    [self.imageData appendData:data];

    if ((self.options & SDWebImageDownloaderProgressiveDownload) && self.expectedSize > 0 && self.completedBlock) {
        // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
        // Thanks to the author @Nyx0uf

        // Get the total bytes downloaded
        const NSInteger totalSize = self.imageData.length;

        // Update the data source, we must pass ALL the data, not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
        CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)self.imageData, totalSize == self.expectedSize);

        if (width + height == 0) {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties) {
                NSInteger orientationValue = -1;
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
                CFRelease(properties);

                // When we draw to Core Graphics, we lose orientation information,
                // which means the image below born of initWithCGIImage will be
                // oriented incorrectly sometimes. (Unlike the image born of initWithData
                // in connectionDidFinishLoading.) So save it here and pass it on later.
                orientation = [[self class] orientationFromPropertyValue:(orientationValue == -1 ? 1 : orientationValue)];
            }

        }

        if (width + height > 0 && totalSize < self.expectedSize) {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

#ifdef TARGET_OS_IPHONE
            // Workaround for iOS anamorphic image
            if (partialImageRef) {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext) {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif

            if (partialImageRef) {
                UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:orientation];
                UIImage *scaledImage = [self scaledImageForKey:self.smbItem.path image:image];
                image = [UIImage decodedImageWithImage:scaledImage];
                CGImageRelease(partialImageRef);
                dispatch_main_sync_safe(^{
                    if (self.completedBlock) {
                        self.completedBlock(image, nil, nil, NO);
                    }
                });
            }
        }

        CFRelease(imageSource);
    }

    if (self.progressBlock) {
        self.progressBlock(self.imageData.length, self.expectedSize);
    }
}

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return SDScaledImageForKey(key, image);
}


- (void) smbConnectionDidFinishLoading
{
    CFRunLoopStop(CFRunLoopGetCurrent());

    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    SDWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;

    if (completionBlock) {
        if (self.options & SDWebImageDownloaderIgnoreCachedResponse && responseFromCached) {
            completionBlock(nil, nil, nil, YES);
            self.completionBlock = nil;
            [self done];
        }
        else {
            UIImage *image = [UIImage sd_imageWithData:self.imageData];

//            image = [self scaledImageForKey:self.smbItem.path image:image];
//            
//            if (!image.images) // Do not force decod animated GIFs
//            {
//                image = [UIImage decodedImageWithImage:image];
//            }
            
            if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                completionBlock(nil, nil, [NSError errorWithDomain:@"SDWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}], YES);
            }
            else {
                completionBlock(image, self.imageData, nil, YES);
            }
            self.completionBlock = nil;
            [self done];
        }
    }
    else {
        [self done];
    }
}

- (void)smbConnection:(KxSMBItemFile *)smbFile didFailWithError:(NSError *)error {
    CFRunLoopStop(CFRunLoopGetCurrent());
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if (self.completedBlock) {
        self.completedBlock(nil, nil, error, YES);
    }

    [self done];
}


- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & SDWebImageDownloaderContinueInBackground;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

@end
