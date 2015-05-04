//
//  serializeTool.m
//  GenieiPad
//
//  Created by liaogang on 7/17/14.
//
//

#import "serializeTool.h"
#import "MAAssert.h"

#if !__has_feature(objc_arc)
#error  This file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif




#define assertValidAccount(a) MAAssert(a && a.length>4)
#define assertValidPassword(p) MAAssert(p && p.length>2)
#define assertValidToken(t)  MAAssert(t && t.length>2)





static NSString * fileName = @".genieCloudAccountData.plist";
static NSMutableDictionary *_sDic = nil ;
static NSString *_strFile ;

static const NSString *kKeyPassword = @"Password";
static const NSString *kKeyToken = @"Token";

#ifdef DEBUG
static bool bInit = false;
#endif


#ifdef TEST
void serializeToolEraseFile()
{
    NSFileManager *fmanager=[NSFileManager defaultManager];
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    
    _strFile = [[NSString alloc]initWithFormat:@"%@/%@",rootPath,fileName];
    
    NSError *error;
    [fmanager removeItemAtPath:_strFile error:&error];
}
#endif


void serializeToolOpen()
{
    #ifdef DEBUG
    if (bInit == false) {
    #endif
        
        NSFileManager *fmanager=[NSFileManager defaultManager];
        
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        
        _strFile = [[NSString alloc]initWithFormat:@"%@/%@",rootPath,fileName];
        
        
        if ([fmanager fileExistsAtPath:_strFile]==NO)
            [fmanager createFileAtPath:_strFile contents:nil attributes:nil];
        
        
        _sDic=[[NSMutableDictionary alloc]initWithContentsOfFile:_strFile];
        if (_sDic == nil)
            _sDic = [NSMutableDictionary dictionary];
        
        
        #ifdef DEBUG
        NSLog(@"%@",_sDic);
        bInit = true;
    }
    else
        MAAssert(false);
    #endif
}

void serializeToolSave()
{
    [_sDic writeToFile:_strFile atomically:YES];
}


NSString *getPasswordOfAccount(NSString *account)
{
    MAAssert(bInit);
    NSDictionary *d = _sDic[account];
    if (d) {
        return  d[kKeyPassword];
    }
    
    return nil;
    
}



/**Login locally
 * return : token of the email account if password is corrent.
 */
NSString *getTokenOfAccount(NSString *account )
{
    MAAssert(bInit);
    NSDictionary *d = _sDic[account];
    if (d) {
        return  d[kKeyToken];
    }
    
    return nil;
}


bool passwordCorrect(NSString *account, NSString *password)
{
    MAAssert(bInit);
    assertValidAccount(account);
    assertValidPassword(password);
    
    return [getPasswordOfAccount(account) isEqualToString:password];
}

NSString *getTokenOfAccountIfPasswordCorrect(NSString *account , NSString *password)
{
    MAAssert(bInit);
    assertValidAccount(account);
    assertValidPassword(password);
    
    if (passwordCorrect(account, password)) {
        return getTokenOfAccount(account);
    }
    
    return nil;
}







/**Save login status
 *save or add account item.
 */
void saveAccountValue(NSString *account , NSString *password , NSString *token)
{
    MAAssert(bInit);
    assertValidAccount(account);
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (password )
        d[kKeyPassword]=password;
    
    if (token)
        d[kKeyToken]=token;
    
    [_sDic setObject:d forKey:account];
}



/**delete login cache.
 *remove or add account item.
 */
void removeTokenOfAccount(NSString *account )
{
    MAAssert(bInit);
    NSDictionary *d = _sDic[account];
    if(d){
        NSMutableDictionary *md =  [NSMutableDictionary dictionaryWithDictionary:d];
        [md removeObjectForKey:kKeyToken];
        
        _sDic[account]=md;
    }
    
}







void removePasswordOfAccount(NSString *account )
{
    MAAssert(bInit);
    NSDictionary *d = _sDic[account];
    if(d){
        NSMutableDictionary *md =  [NSMutableDictionary dictionaryWithDictionary:d];
        [md removeObjectForKey:kKeyPassword];
        
        _sDic[account]=md;
    }
    
   
}



