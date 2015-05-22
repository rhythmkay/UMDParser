//
//  UMDParser.h
//  reader.multidocs
//
//  Created by rhythmzhang on 15-2-2.
//  Copyright (c) 2015年 rhythmzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Util.h"
#import "UMDMetadata.h"

//umd 采用unicode编码

#define UMD_TAG_MIME (0xde9a9b89) //umd文件标识
#define UMD_TYPE_TEXT (0x0001) //纯文本UMD
#define UMD_TYPE_CARTOON (0x0002) //动漫UMD

#define UMD_TAG_SPILT            (0x0023) //'#'分隔符
#define UMD_TAG_TITLE            (0x0002) //2字节，标题
#define UMD_TAG_AUTHOR           (0x0003) //作者
#define UMD_TAG_PUB_YEAR         (0x0004) //出版年
#define UMD_TAG_PUB_MONTH        (0x0005) //出版月
#define UMD_TAG_PUB_DATE         (0x0006)
#define UMD_TAG_TYPE             (0x0007) //小说类型
#define UMD_TAG_PUBLISHER        (0x0008) //出版商
#define UMD_TAG_RETAILER         (0x0009) //零售商

#define UMD_TAG_CONTENT_LENGTH   (0x000b) //文章解压缩后总大小（或者章节内容总大小之和）,可用于标识其后的为正文实际内容


#define UMD_TAG_CHAPTER_OFFSET   (0x0083) //标识,章节偏移

#define UMD_TAG_CHAPTER_TITLE    (0x0084) //标识,章节标题


#define UMD_TAG_CONTENT_START    (0x0024) //标识,正文数据块开始

#define UMD_TAG_CHUNK_F          (0x00f1) //chunk块结束标识1
#define UMD_TAG_CHUNK_A          (0x000a) //chunk块结束标识2

#define UMD_TAG_CONTENT_END          (0x0081) //umd正文结束标识


#define UMD_TAG_COVER          (0x0082) //cover封面
#define UMD_TAG_FINISHED          (0x000c) //文件结束标识

#define UMD_DECOMPRESSED_EXTENSION @"utx" //存放解压后的umd文件的后缀名
#define UMD_COVER_EXTENSION @"jpg" //存放解压后的umd cover文件后缀名

#define DATA_BYTES_1 1
#define DATA_BYTES_2 2
#define DATA_BYTES_3 3
#define DATA_BYTES_4 4
#define DATA_BYTES_5 5

#define DATA_CONTENT_LENGTH 9

//这个是那几个需要减9的常量数值定义
#define DATA_SPILT_LENGTH 9


//跳过XX个字节
#define UMD_NEXT_12 12


#define UMD_DECOMPRESSED_BUFFER_SIZE 32*1024  //32字节缓存大小


//重新定义一些数据类型，只要求字节类型的int值.
typedef unsigned char UInteger1;
typedef unsigned short UInteger2;
typedef unsigned int UInteger4;


@interface UMDParser : NSObject
{
    NSFileHandle *_handle;
    unsigned long long _offset;
    unsigned long long _fileLength;
    
    unsigned long long _contentLength; //真正的所有内容的字节长度数目..

    //当解压完毕就OK
    NSFileHandle *_utxHandle; //分析解压后的txt文本的文件操作...
    unsigned long long _utxContentLength;

    
}

@property (nonatomic, readonly, strong) NSURL *url;//文件路径..

@property (nonatomic, readonly, strong) NSURL *destURL;  //解压后的目标

@property (nonatomic, readonly, strong) NSURL *baseURL; //解压后的基础路径...==destURL+srcUmdFileName不带后缀名.umd

@property (nonatomic, readonly, strong) NSURL *utxURL; //解压后合并在同一个.umd.utx文件的绝对路径.==baseURL+fileName+后缀名.

@property (nonatomic, readonly, strong) NSMutableArray *chapters; //章节信息....

@property (nonatomic, readonly, strong) UMDMetadata *metaData; //metaData.

/*
 传递章节编号index(index从0开始)，返回对应章节的所有内容
 index从0开始，代表第index+1章节的内容
*/
-(NSString*)contentForChapter:(int)index; //....

- (instancetype)initWithFileURL:(NSURL *)t_url andDestinationFolder:(NSURL *)t_destURL;

//-(BOOL)isUMD;

/*
 这里是真正的一个个字节的来处理umd文件.
 开始解析UMD文件处理,成功返回YES,否则NO
 
 UMD文件的parse必须一次性的连续的完成所有，因为首先umd文件基本不会太大，而且由于是连续的文件，所以只能一次性的解析.
 
*/
-(BOOL)parse;



@end
