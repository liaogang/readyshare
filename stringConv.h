#include <string>
#pragma once



#ifdef _WIN_NT
LPSTR Unicode2Ansi(LPCWSTR s);
LPSTR Unicode2UTF8(LPWSTR s);
LPWSTR Ansi2Unicode(LPSTR s);
LPWSTR UTF82Unicode(LPSTR s);
#else
int UTF8StrToUnicodeStr (unsigned char * utf8_str,
                         unsigned short * unicode_str, int unicode_str_size);
int UTF8ToUnicode (unsigned char *ch, int *unicode);
char*  _itoa(int num , char *str , int radix);
#endif


//convent a string to send in network.
std::string str2UnicodeCode(const char *c,int len, bool bTing = false );

std::string unicodeCode2str(const char *c,int len);


int utf8unicode(const char *src , char *out);





/**检测一段Unicode字符是否为utf-8编码方式.
 * param : utf8nums 最大检测符合utf8的字符数 ,默认为全部都要检测
 */
bool isUtf8(const char *pBuf,int bufLen , unsigned int utf8numsMax = -1 );










//-----------------------------------------
//read file with encode UTF8 or UTF16 or ANSI (DBCS)
//-----------------------------------------
/**
 *UCS 即 Universal Multiple-Octet Coded Character Set (unicode)
 *UTF-8 : 以8bit为基本传输单位.     变长 UCS Transfer Format 传输方式
 *UTF-16: 双16bit为基本传输单位     UCS 传输方式
 *UTF-32: 以32bit为基本传输单位     目前用得不多
 *unix里没有用DBCS的.基本以ucs为主
 */
enum ENCODETYPE 
{
	UNKNOW,
	ANSI,
    DBCS = ANSI ,
    GBK = DBCS ,
	UTF8,
	UTF16_big_endian,
	UTF16_little_endian
};

ENCODETYPE TellEncodeType(char* pBuf,int bufLen);

#ifdef APP_PLAYER_UI
void CleanAfterFileCovert(BYTE* pBufOld,BYTE *pBufNew);
void CovertFileBuf2UTF16littleEndian(BYTE* pBuf,int bufLen,ENCODETYPE filetype,OUT TCHAR **pBufU,OUT int &filesizeAfterCovert);
int MyGetLine(TCHAR *pBuf,int bufLen,std::wstring &str);

int StringCmpNoCase(std::tstring a,std::tstring b);
int StrCmpIgnoreCaseAndSpace(std::tstring a,std::tstring b);
int hex2dec(char c);


void trimLeftAndRightSpace(std::tstring &str);
void TrimRightByNull(std::wstring &_str);


LONG GetStrSizeX(HDC dc,TCHAR *str);
//void MakeShortString(HDC dc,TCHAR *str,long width);

//void DrawTriangleInRect(HDC dc,RECT &rc);

#endif
