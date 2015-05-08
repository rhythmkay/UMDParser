//
//  Util.m
//  wifiTransfer
//
//  Created by Apple on 8/22/14.
//  Copyright (c) 2014 rhythm. All rights reserved.
//

#import "Util.h"

static int UTIL_DirDepth(const char *str)
{
    int count=0;
    if(str)
    {
        const char *p=str;
        while(*(p+1)!='\0')
        {
            if(*p=='/')
                count++;
            ++p;
        }
        
    }
    return count;
}

@implementation Util


/***********与文件相关的**************************/
+ (unsigned long long)fileLengthWithFile:(NSString *)fileAbsoluteName{
	if (fileAbsoluteName== nil) {
		return (0);
	}
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = fileAbsoluteName;
	NSError *error;
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&error];
	if (!fileAttributes) {
		NSLog(@"%@",error);
		return (0);
	}
	return [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
}

+(NSURL*)documentsURL{
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

}

+(NSURL*)resourceURL{
    return [[NSBundle mainBundle] resourceURL];
}


+(void)createDirAtPath:(NSString*)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}


//这样生成URL才对
+(NSURL*)URLWithLocalFilePath:(NSString*)filePath{
    
    static NSString *filePreffix=@"file://";
    if(![filePath hasPrefix:filePreffix])
    {
        filePath=[NSString stringWithFormat:@"%@%@",filePreffix,filePath];
    }
    
    //一定要这样才对...生成NSURL需要UTF8编码转换....
    filePath=[filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:filePath];
}



+(void)createDirectoryIfNeeded:(const char *)fileName destPath:(NSString*)path
{
    if(UTIL_DirDepth(fileName)>0) //改...
    {
        NSString *strPath = [NSString stringWithCString:fileName encoding:NSUTF8StringEncoding];
        strPath=[strPath stringByDeletingLastPathComponent]; //把最后的包含文件名的路径给去掉，只留文件夹...
        
        NSString *fullPath = [path stringByAppendingPathComponent:strPath];
        
        [Util createDirAtPath:fullPath];
    }
}


//修复文件的//文件夹符号为/符号即可.
+(NSString*)filePathFix:(NSString*)strPath
{
    if ([strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location != NSNotFound)
    
        strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    return strPath;
}


+(NSString*)fileNameWithOutExtension:(NSString *)path
{
    return [[path lastPathComponent] stringByDeletingPathExtension];
    
}


//转为UNICODE STRING
+(NSString*)dataToUnicodeString:(NSData*)data
{
    //UInteger2 bom=0xfeff;
    unsigned short bom=0xfeff;
    //这个FEFF时unicode,ucs-2 littile endian编码的文件开头字节必备的唯一标识.
    NSMutableData *strData=[[NSMutableData alloc] initWithBytes:&bom length:2];
    if(data)
        [strData appendData:data];
    return [[NSString alloc] initWithData:strData encoding:NSUnicodeStringEncoding];
}




@end
