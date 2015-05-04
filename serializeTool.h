//
//  serializeTool.h
//  GenieiPad
//
//  Created by liaogang on 7/17/14.
//
//

#import <Foundation/Foundation.h>


/**Genie cloud auth local.
 * account : email in cloud.
 */


/**data struture in file.
 @{
    @{  @"accountName":
        @{
            @"password":@"123456",
            @"token":@"tokenxxx"
        }
    }
    ,
     @{  
         @"accountName2":
             @{
             @"password":@"12345632",
             @"token":@"tokenxxx234234"
             }
     }
  }
*
*/







/**Save something ( password and token ) of a account
*this will overwrite the old one.
*add one item if account if not exists.
*/
void saveAccountValue(NSString *account , NSString *password , NSString *token);



/**Get something of a account.
 */
NSString *getPasswordOfAccount(NSString *account);
NSString *getTokenOfAccount(NSString *account );
NSString *getTokenOfAccountIfPasswordCorrect(NSString *account , NSString *password);




/**delete login cache.
*remove or add account item.
*/
void removeTokenOfAccount(NSString *account );
void removePasswordOfAccount(NSString *account );



/**auth wether the password of a account is correct.
*/
bool passwordCorrect(NSString *account, NSString *password);







#ifdef TEST
void serializeToolEraseFile();
#endif


///this code should be call one time at init.
void serializeToolOpen();
///put this in app will enter background.
void serializeToolSave();





