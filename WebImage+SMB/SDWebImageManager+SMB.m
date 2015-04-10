/*
 *Image view with smb url support
 *Include caches and cancel operation.
 *download while app is in background
 *Handle single download of simultaneous download request for the same URL
 */



#import "SDWebImageManager+SMB.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"
#import "KxSMBProvider.h"
#import "SDWebImageDownloaderOperation+SMB.h"
#import <Foundation/Foundation.h>
#import "objc/runtime.h"


static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

static char operationKey;

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) void (^cancelBlock)();
@property (strong, nonatomic) NSOperation *cacheOperation;

@end

@interface SDWebImageManager(sdweb_smb)
- (id <SDWebImageOperation>)downloadWithSmbItem:(KxSMBItemFile *)smbItem options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock ;
@end

@implementation SDWebImageManager (smb)

- (NSString *)cacheKeyForSmbFile:(KxSMBItemFile *)smbFile {
        return smbFile.path ;
}

- (BOOL)diskImageExistsForSmbFile:(KxSMBItemFile *)smbFile {
    NSString *key = [self cacheKeyForSmbFile:smbFile];
    return [self.imageCache diskImageExistsWithKey:key];
}


@end


@implementation UIImageView (WebCache_Smb)

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile  needRefresh:(BOOL)needRefresh{
    [self setImageWithSmbItem:smbFile placeholderImage:nil options:0 progress:nil completed:nil needRefresh:needRefresh];
}

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile  placeholderImage:(UIImage *)placeholder  needRefresh:(BOOL)needRefresh{
    [self setImageWithSmbItem:smbFile placeholderImage:placeholder options:0 progress:nil completed:nil needRefresh:needRefresh];
}

- (void)setImageWithSmbFile:(KxSMBItemFile *)smbFile placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock  needRefresh:(BOOL)needRefresh{
    [self setImageWithSmbItem:smbFile placeholderImage:placeholder options:0 progress:nil completed:completedBlock needRefresh:needRefresh];
}

- (void)setImageWithSmbItem:(KxSMBItemFile *)smbItem placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock needRefresh:(BOOL)needRefresh
{
    [self cancelCurrentImageLoad];
    
    self.image = placeholder;
    
    if (smbItem) {
        __weak UIImageView *wself = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithSmbItem:smbItem options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                if (!wself) return;
                if (image) {

                    if(needRefresh)
                    {
                        wself.image = image;
                        [wself setNeedsLayout];
                    }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType);
                }
                    }
            });
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }}


@end


@implementation SDWebImageDownloader (sdweb_smb)
- (id <SDWebImageOperation>)downloadImageWithSmbItemFile:(KxSMBItemFile *)smbItem options:(SDWebImageDownloaderOptions)options progress:(void (^)(NSInteger, NSInteger))progressBlock completed:(void (^)(UIImage *, NSData *, NSError *, BOOL))completedBlock
{
    
    __block SDWebImageDownloaderOperation_SMB *operation;
    __weak SDWebImageDownloader *wself = self;
    
    [self addProgressCallback:progressBlock andCompletedBlock:completedBlock forSmbFile:smbItem createCallback:^{
//        NSTimeInterval timeoutInterval = wself.downloadTimeout;
//        if (timeoutInterval == 0.0) {
//            timeoutInterval = 15.0;
//        }
        
        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        operation = [[SDWebImageDownloaderOperation_SMB alloc] initWithSmbItem:smbItem
                                                                       options:options
                                                                      progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                                          if (!wself) return;
                                                                          SDWebImageDownloader *sself = wself;
                                                                          NSArray *callbacksForURL = [sself callbacksForSmbFile:smbItem];
                                                                          for (NSDictionary *callbacks in callbacksForURL) {
                                                                              SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                                                                              if (callback) callback(receivedSize, expectedSize);
                                                                          }
                                                                      }
                                                                     completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                         if (!wself) return;
                                                                         SDWebImageDownloader *sself = wself;
                                                                         NSArray *callbacksForURL = [sself callbacksForSmbFile:smbItem];
                                                                         if (finished) {
                                                                             [sself removeCallbacksForSmbFile:smbItem];
                                                                         }
                                                                         for (NSDictionary *callbacks in callbacksForURL) {
                                                                             SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                                                                             if (callback) callback(image, data, error, finished);
                                                                         }
                                                                     }
                                                                     cancelled:^{
                                                                         if (!wself) return;
                                                                         SDWebImageDownloader *sself = wself;
                                                                         [sself removeCallbacksForSmbFile:smbItem];
                                                                     }];
        
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        }
        
        @synchronized(operation)
        {
            if(!operation.isCancelled){
        [wself.downloadQueue addOperation:operation];
        if (wself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
            }}}
        
        ];
    
    return operation;
}


- (void)addProgressCallback:(void (^)(NSInteger, NSInteger))progressBlock andCompletedBlock:(void (^)(UIImage *, NSData *data, NSError *, BOOL))completedBlock forSmbFile:(KxSMBItemFile *)smbFile createCallback:(void (^)())createCallback {
    
    NSString *url = smbFile.path;
    
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (smbFile == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.smbCallbacks[url]) {
            self.smbCallbacks[url] = [NSMutableArray new];
            first = YES;
        }
        
        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.smbCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.smbCallbacks[url] = callbacksForURL;
        

        if (first) {
            createCallback();
        }
    });
}

- (NSArray *)callbacksForSmbFile:(KxSMBItemFile *)smbFile {
    NSString *url = smbFile.path;

    __block NSArray *callbacksForURL;
    dispatch_sync(self.barrierQueue, ^{
        callbacksForURL = self.smbCallbacks[url];
    });
    return [callbacksForURL copy];
}

- (void)removeCallbacksForSmbFile:(KxSMBItemFile *)smbFile {
    NSString *url = smbFile.path;

    dispatch_barrier_async(self.barrierQueue, ^{
        [self.smbCallbacks removeObjectForKey:url];
    });
}

@end





@implementation SDWebImageManager (sdweb_smb)

- (id <SDWebImageOperation>)downloadWithSmbItem:(KxSMBItemFile *)smbItem options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock {
    
    // Invoking this method without a completedBlock is pointless
    NSParameterAssert(completedBlock);

    
    __block SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    __weak SDWebImageCombinedOperation *weakOperation = operation;
    
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    
    NSString *key = [self cacheKeyForSmbFile:smbItem];
    
    operation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType) {
        if (operation.isCancelled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
            
            return;
        }
        
        if (!image || options & SDWebImageRefreshCached)
        {
            if (image && options & SDWebImageRefreshCached) {
                dispatch_main_sync_safe(^{
                    // If image was found in the cache bug SDWebImageRefreshCached is provided, notify about the cached image
                    // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                    completedBlock(image, nil, cacheType, YES);
                });
            }
            
            // download if no image or requested to refresh anyway, and download allowed by delegate
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (image && options & SDWebImageRefreshCached) {
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
            
            
            id <SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithSmbItemFile:smbItem options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                if (weakOperation.isCancelled) {
                    dispatch_main_sync_safe(^{
                        completedBlock(nil, nil, SDImageCacheTypeNone, finished);
                    });
                }
                else if (error) {
                    dispatch_main_sync_safe(^{
                        completedBlock(nil, error, SDImageCacheTypeNone, finished);
                    });
                    
                }
                else {
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);
                    
                    if (options & SDWebImageRefreshCached && image && !downloadedImage) {
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                    }
                    else {
                        dispatch_main_sync_safe(^{
                            completedBlock(downloadedImage, nil, SDImageCacheTypeNone, finished);
                        });
                        
                        if (downloadedImage && finished) {
                            [self.imageCache storeImage:downloadedImage recalculateFromImage:NO imageData:data forKey:key toDisk:cacheOnDisk];
                        }
                    }
                }
                
                if (finished) {
                    @synchronized (self.runningOperations) {
                        [self.runningOperations removeObject:operation];
                    }
                }
            }];
            operation.cancelBlock = ^{
                [subOperation cancel];
            };
        }
        else if (image) {
            dispatch_main_sync_safe(^{
                completedBlock(image, nil, cacheType, YES);
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
        else {
            // Image not in cache and download disallowed by delegate
            dispatch_main_sync_safe(^{
                completedBlock(nil, nil, SDImageCacheTypeNone, YES);
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
    }];
    
    return operation;
}

@end





