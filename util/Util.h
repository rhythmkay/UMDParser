//
//  Util.h
//  wifiTransfer
//
//  Created by rhythmzhang on 8/22/14.
//  Copyright (c) 2014 rhythmzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>



extern NSString *const kEPUBTextExtension;

@interface Util : NSObject


/*************根据文件绝对路径，返回文件大小信息**************/
+ (unsigned long long)fileLengthWithFile:(NSString *)fileAbsoluteName;

+(NSURL*)documentsURL;
+(NSURL*)resourceURL;

+(void)createDirAtPath:(NSString*)path;
+(NSURL*)URLWithLocalFilePath:(NSString*)filePath;

/*************file path***************/
+(NSString*)filePathFix:(NSString*)strPath;
+(void)createDirectoryIfNeeded:(const char *)fileName destPath:(NSString*)path;
+(NSString*)fileNameWithOutExtension:(NSString *)path;

/*************转为UNICODE STRING,UMD专用***************/
+(NSString*)dataToUnicodeString:(NSData*)data;

@end
