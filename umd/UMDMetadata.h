//
//  UMDMetadata.h
//  reader.multidocs
//
//  Created by jeruizhang on 15-2-2.
//  Copyright (c) 2015年 rhythmzhang. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface UMDChapter : NSObject

//@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, strong) NSString *title; //章节标题
@property (nonatomic, strong) NSString *src; //章节对应的文件路径...???
@property (nonatomic, assign) unsigned long long offset; //对应的文件偏移起始地址
@property (nonatomic, assign) unsigned long long length; //对应的文件大小

@end

@interface UMDMetadata : NSObject

@property (nonatomic, strong) NSString *title;  //标题，书名.
@property (nonatomic, strong) NSString *author; //作者.
@property (nonatomic, strong) NSString *pubDate; //出版日期
@property (nonatomic, strong) NSString *type; //小说类型
@property (nonatomic, strong) NSString *publisher; //出版商
@property (nonatomic, strong) NSString *retailer; //零售商


@property (nonatomic, strong) NSString *cover; //cover的路径

@end
