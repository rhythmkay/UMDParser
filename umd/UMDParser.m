//
//  UMDParser.m
//  reader.multidocs
//
//  Created by rhythmzhang on 15-2-2.
//  Copyright (c) 2015年 rhythmzhang. All rights reserved.
//

#import "UMDParser.h"
#import "zlib.h"

@implementation UMDParser

- (instancetype)initWithFileURL:(NSURL *)t_url andDestinationFolder:(NSURL *)t_destURL{
    
    if(self=[super init])
    {
        _url=t_url;
        _destURL=t_destURL;
    }
    return  self;
}

-(void)dealloc{
    
    if(_utxHandle)
    {
        [_utxHandle closeFile];
    }
}


/*
 判断是否为UMD文件
 */
-(BOOL)isUMD{
    
    
    _fileLength=[Util fileLengthWithFile:self.url.path];
    _handle=[NSFileHandle fileHandleForReadingAtPath:self.url.path];
    
    //read first 4 bytes;
    NSData *data=[_handle readDataOfLength:DATA_BYTES_4];
    _offset=[_handle offsetInFile];
    UInteger4 mime;
    [data getBytes:&mime length:[data length]];
    if(UMD_TAG_MIME==mime)
        return YES;
    else
        return NO;
}

/*
 用来跳过当前bytes个字节.
 */
-(void)nextBytes:(unsigned int) bytes{
    unsigned long long t_offset=[_handle offsetInFile]+bytes;
    if(t_offset>_fileLength)
    {
        NSLog(@"error nextBytes,out of file length");
        return ;
    }
    else
        [_handle seekToFileOffset:t_offset];
}

/*
 用来跳过会退到bytes个字节.
 */
-(void)previousBytes:(unsigned int) bytes{
    if([_handle offsetInFile]<bytes)
        [_handle seekToFileOffset:4]; //跳回去....
    else
    [_handle seekToFileOffset:[_handle offsetInFile]-bytes]; //跳过这2个无意义字节.
}


/*
 将umd源文件的data转为合法的unicode字符.
 */
-(NSString*)dataToUnicodeString:(NSData*)data
{
    UInteger2 bom=0xfeff;
    NSMutableData *strData=[[NSMutableData alloc] initWithBytes:&bom length:2];
    if(data)
        [strData appendData:data];
    return [[NSString alloc] initWithData:strData encoding:NSUnicodeStringEncoding];
}


-(BOOL)parse{
    
    BOOL ok=NO;
    
    if(![self isUMD])
    {
        NSLog(@"illegal mime,it's not umd file.");
        
        if(_handle)
        {
            [_handle closeFile];
            _handle=nil;
        }
        
        return ok;
    }
    
    _offset=[_handle offsetInFile];
    _metaData=[UMDMetadata new];
    
    NSData *data;
    //开始第5个字节读取...
    [_handle seekToFileOffset:[_handle offsetInFile]+5]; //跳过这5个无意义字节.
    UInteger1 umd_type; //1字节
    data=[_handle readDataOfLength:DATA_BYTES_1];
    [data getBytes:&umd_type length:[data length]];
    switch(umd_type)
    {
        case UMD_TYPE_TEXT:
            NSLog(@"纯文本UMD");
            break;
        case UMD_TYPE_CARTOON:
            NSLog(@"动漫UMD,无法解析，程序退出.");
            return ok; //结束，无法解析动漫UMD
            break;
        default:
            NSLog(@"ERROR UMD,未知类型的UMD文件");
            return ok;
    }
    
    [self nextBytes:DATA_BYTES_2]; //跳过这2个无意义字节.

    //开始读取UMD文件的基本META属性，入作者，标题，等...
    BOOL isAttrEnd=NO;
    NSString *str;
    
    NSLog(@"读取属性");
    //这里应该一次性读5个字节才对
    while(!isAttrEnd)
    {
        //循环读取5字节.
        data=[_handle readDataOfLength:DATA_BYTES_5];
        
        UInteger1 tag_spilt;
        [data getBytes:&tag_spilt range:NSMakeRange(0, 1)]; //第一个字节,一定为'#'
        UInteger2 tag_attr;
        [data getBytes:&tag_attr range:NSMakeRange(1, 2)];//第2，3个字节，共2字节
        
        //空的1字节.不处理.
        
        if(UMD_TAG_SPILT==tag_spilt)
        {
            UInteger1 tag_length;
            [data getBytes:&tag_length range:NSMakeRange(4, 1)]; //第4个字节，最后一个字节.
            UInteger1 content_length=tag_length-5; //内容长度,必须减5.
            
            switch(tag_attr)
            {
                case UMD_TAG_TITLE:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.title=str;
                    break;
                }
                case UMD_TAG_AUTHOR:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.author=str;
                    break;
                }

                case UMD_TAG_PUB_YEAR:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.pubDate=[NSString stringWithFormat:@"%@-",str];
                    break;
                }

                case UMD_TAG_PUB_MONTH:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.pubDate=[_metaData.pubDate stringByAppendingFormat:@"%@-",str];
                    break;
                }
                    
                case UMD_TAG_PUB_DATE:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.pubDate=[_metaData.pubDate stringByAppendingFormat:@"%@",str];
                    break;
                }

                case UMD_TAG_TYPE:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.type=str;
                    break;
                }

                case UMD_TAG_PUBLISHER:
                {
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    _metaData.publisher=str;
                    break;
                }

                case UMD_TAG_RETAILER:
                {
                    //data=[_handle readDataOfLength:content_length];
                    str=[self dataToUnicodeString:[_handle readDataOfLength:content_length]];
                    //[self dataToUnicodeString:data];
                    _metaData.retailer=str;
                    break;
                }

                case UMD_TAG_CONTENT_LENGTH:
                {
                    data=[_handle readDataOfLength:DATA_BYTES_4]; //9字节
                    UInteger4 tag_length;
                    [data getBytes:&tag_length length:DATA_BYTES_4];
                    _contentLength=tag_length;
                    //NSLog(@"_contentLength=%lli",_contentLength);
                    break;
                }
                default:
                {
                    [self previousBytes:DATA_BYTES_5]; //此处也会多度了，然后回退.
                    isAttrEnd=YES; //跳出当前while循环,属性读取完毕.
                    break;
                }

            }
        }
        else
        {
            [self previousBytes:DATA_BYTES_5]; //回退.
            NSLog(@"illegal tag spilt,break.");
            break;
        }
        
    }
    
    
    

    //开始读取章节目录
    data=nil; //时不时的清空自己.
    UInteger1 tag_spilt;
    //读取章节偏移量.
    //读18个字节.
    _chapters=[[NSMutableArray alloc] init];
    NSLog(@"读取章节偏移量信息");
    data=[_handle readDataOfLength:18];
    [data getBytes:&tag_spilt range:NSMakeRange(0, 1)];
    if(UMD_TAG_SPILT==tag_spilt)
    {
        UInteger2 tag_attr;
        [data getBytes:&tag_attr range:NSMakeRange(1, 2)];
        if(UMD_TAG_CHAPTER_OFFSET==tag_attr)
        {
            UInteger4 chapter_count;
            [data getBytes:&chapter_count range:NSMakeRange([data length]-DATA_BYTES_4, DATA_BYTES_4)]; //最后4字节.
            if(chapter_count>0)
            {
                chapter_count=(chapter_count-DATA_SPILT_LENGTH)>>2; //除以4，右移2位.
                UInteger4 chap_offset=0;
                
                int chap_counter=0;
                while(chap_counter<chapter_count)
                {
                    UMDChapter *chap=[UMDChapter new];
                    data=[_handle readDataOfLength:DATA_BYTES_4];
                    [data getBytes:&chap_offset length:[data length]];
                    chap.offset=chap_offset;
                    chap_counter++;
                    [_chapters addObject:chap];
                }
            }
        }
        
    }
    else
    {
        NSLog(@"error,章节偏移量解析出错.");
        return ok;
    }
    data=nil;
    
    NSLog(@"读取章节标题");
    data=[_handle readDataOfLength:18];
    [data getBytes:&tag_spilt range:NSMakeRange(0, 1)];
    if(UMD_TAG_SPILT==tag_spilt)
    {
        UInteger2 tag_attr;
        [data getBytes:&tag_attr range:NSMakeRange(1, 2)];
        if(UMD_TAG_CHAPTER_TITLE==tag_attr)
        {
            UInteger4 chapter_title_length;
            [data getBytes:&chapter_title_length range:NSMakeRange([data length]-DATA_BYTES_4, DATA_BYTES_4)]; //最后4字节.
            for(UMDChapter *chap in _chapters)
            {
                data=[_handle readDataOfLength:DATA_BYTES_1];
                UInteger1 title_length;
                [data getBytes:&title_length length:[data length]];
                data=[_handle readDataOfLength:title_length];
                chap.title=[self dataToUnicodeString:data];
            }
            
        }
        
    }
    else
    {
        NSLog(@"error,章节标题出错.");
        return ok;
    }
    data=nil;
    
    //接下来是正文数据了咯.......
    //为了避免过多内存占用，将把解析的正文数据块先统一的写入本地文件....
    //边解析边解压缩然后写入文件,这样就是一个完整的unicode编码的纯文本了呢....
    
    NSFileHandle *fileHandle=[self createDecompressFile];
    
    if(fileHandle)
    {
        BOOL isDataChunkEnd=NO;
        
        //采用BUFFER方式优化读写.
        NSMutableData *buffer=[[NSMutableData alloc] init];

        while(!isDataChunkEnd)
        {
            data=[_handle readDataOfLength:DATA_BYTES_1];
            UInteger1 tag_spilt;
            [data getBytes:&tag_spilt length:[data length]];

            if(UMD_TAG_CONTENT_START==tag_spilt)
            {
                [self nextBytes:DATA_BYTES_4];//跳过4个随机数字节
                UInteger4 chunk_compressed_length;
                data=[_handle readDataOfLength:DATA_BYTES_4];
                [data getBytes:&chunk_compressed_length length:[data length]];
                chunk_compressed_length-=DATA_SPILT_LENGTH; //减9才是实际压缩块数据的大小
                data=[_handle readDataOfLength:chunk_compressed_length];

                data=[self uncompress:data];
                
                [buffer appendData:data];
                data=nil;
                if([buffer length]>UMD_DECOMPRESSED_BUFFER_SIZE)
                {
                    [fileHandle writeData:buffer];
                    [buffer setLength:0];
                }
                
            }
            else if(UMD_TAG_SPILT==tag_spilt)
            {
                data=[_handle readDataOfLength:DATA_BYTES_2];
                UInteger2 tag_chunk_end;
                [data getBytes:&tag_chunk_end length:[data length]];
                switch(tag_chunk_end)
                {
                    case UMD_TAG_CHUNK_F:
                        [self nextBytes:18]; //跳过18字节
                        break;
                    case UMD_TAG_CHUNK_A:
                        [self nextBytes:6];//跳过6字节.
                        break;
                    case UMD_TAG_CONTENT_END:
                       // NSLog(@"正文结束");
                        isDataChunkEnd=YES;
                        break;
                }

            }
            else
            {
                NSLog(@"error解析正文");
                break;
            }
            
        }
        
        if([buffer length]>0)
        {
            [fileHandle writeData:buffer];
            [buffer setLength:0]; //clean it....
            buffer=nil; //release it.
        }

        [fileHandle closeFile];
        fileHandle=nil;
        //操作写入完毕，可以结束了......

    }
    else
    {
        NSLog(@"无法写入解析后的数据，fileHandle==nil,退出");
        return ok;
    }
    data=nil;
    
    //正文解析完毕，然后读取封面cover....
    NSLog(@"读取封面");
    //跳过这之间多余的字符
    BOOL isUMDEnd=NO;
    while([_handle offsetInFile]<_fileLength)
    {
        UInteger1 tag_spilt;
        data=[_handle readDataOfLength:DATA_BYTES_1];
        [data getBytes:&tag_spilt length:[data length]];
        if(UMD_TAG_SPILT==tag_spilt)
        {
            UInteger2 tag_attr;
            data=[_handle readDataOfLength:DATA_BYTES_2];
            [data getBytes:&tag_attr length:[data length]];
            switch(tag_attr)
            {
                case UMD_TAG_COVER:
                    //进行封面处理
                    //跳过12字节
                    [self nextBytes:UMD_NEXT_12];
                    UInteger4 tag_cover_length;
                    data=[_handle readDataOfLength:DATA_BYTES_4];
                    [data getBytes:&tag_cover_length length:[data length]];
                    if(tag_cover_length>DATA_SPILT_LENGTH)
                    {
                        tag_cover_length-=DATA_SPILT_LENGTH; //减9
                        //接下来得tag_cover_length就是实际的cover了
                        data=[_handle readDataOfLength:tag_cover_length];
                        _metaData.cover=[self createCoverFile:data];
                    }
                    break;
                case UMD_TAG_FINISHED:
                    NSLog(@"finished...");
                    isUMDEnd=YES;
                    break;
            }
        }
        if(isUMDEnd)
            break; //结束.
        
    }
    data=nil;
    
    
    [_handle closeFile]; //操作结束，关闭文件.
    _handle=nil;
    
    ok=YES; //这里才成功...
    
    return ok;

}


-(NSFileHandle*)createDecompressFile{
    
    NSString *fileName=[[self.url lastPathComponent] stringByDeletingPathExtension];
    _baseURL=[_destURL URLByAppendingPathComponent:fileName];
    [Util createDirAtPath:_baseURL.path];
    _utxURL=[_baseURL URLByAppendingPathComponent:[fileName stringByAppendingPathExtension:UMD_DECOMPRESSED_EXTENSION] isDirectory:NO];
    [[NSFileManager defaultManager] createFileAtPath:_utxURL.path contents:nil attributes:nil];
    NSFileHandle *fileHandle=[NSFileHandle fileHandleForWritingAtPath:_utxURL.path];

    UInteger2 bom=0xfeff;
    [fileHandle writeData:[NSData dataWithBytes:&bom length:DATA_BYTES_2]];
    //先写入unicode编码的bom头部呢..

    return fileHandle;
}


-(NSString*)createCoverFile:(NSData*)data{
    
    if(!data)
        return nil;
    NSString *fileName=[[self.url lastPathComponent] stringByDeletingPathExtension];
    //_baseURl已经在前面的createDecompressFile方法中初始化了.
    NSURL *pathURL=[_baseURL URLByAppendingPathComponent:[fileName stringByAppendingPathExtension:UMD_COVER_EXTENSION] isDirectory:NO];
    [[NSFileManager defaultManager] createFileAtPath:pathURL.path contents:data attributes:nil];
    if([Util fileLengthWithFile:pathURL.path]>1024) //大于1个字节，才说明有图片信息么???
    {
        return pathURL.path;
    }
    return nil;
}


/*****************解压缩，使用zlib即可...本函数代码源于互联网*****************/
- (NSData *)uncompress:(NSData *)zlibData
{
    //auto release pool优化内存占用.
    @autoreleasepool {
    
        if ([zlibData length] == 0) return zlibData;
        
        unsigned long full_length = [zlibData length];
        unsigned long half_length = [zlibData length] / 2;
        
        NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
        BOOL done = NO;
        int status;
        
        z_stream strm;
        strm.next_in = (Bytef *)[zlibData bytes];
        strm.avail_in = (unsigned int)[zlibData length];
        strm.total_out = 0;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        
        if (inflateInit (&strm) != Z_OK) return nil;
        
        while (!done)
        {
            // Make sure we have enough room and reset the lengths.
            if (strm.total_out >= [decompressed length])
                [decompressed increaseLengthBy: half_length];
            strm.next_out = [decompressed mutableBytes] + strm.total_out;
            strm.avail_out =(unsigned int) ([decompressed length] - strm.total_out);
            
            // Inflate another chunk.
            status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END) done = YES;
            else if (status != Z_OK) break;
        }
        if (inflateEnd (&strm) != Z_OK) return nil;
        
        // Set real length.
        if (done)
        {
            [decompressed setLength: strm.total_out];
            return [NSData dataWithData: decompressed];
        }
        else return nil;
    }
    
}


 //index从0开始，代表第index+1章节的内容....
//_chapter存储的offset时解压后的文件的偏移
-(NSString*)contentForChapter:(int)index{
    
    if(index<0||index>=[self.chapters count])
    {
        NSLog(@"非法章节序号.从0开始，小于chapters数目才可");
        return nil;
    }
    
    NSString *content;
    
    if(!_utxHandle&&_utxURL.path)
    {
        _utxHandle=[NSFileHandle fileHandleForReadingAtPath:_utxURL.path];
        _utxContentLength=[Util fileLengthWithFile:_utxURL.path];
    }
    
    UMDChapter *currChap=[self.chapters objectAtIndex:index];
    unsigned long long offset=currChap.offset;
    NSLog(@"chapter=%@",currChap.title);
    unsigned long long length=0;
    if(index+1>=[self.chapters count])
    {
        length=_utxContentLength-offset;
    }
    else
    {
        UMDChapter *nextChap=[self.chapters objectAtIndex:index+1];
        length=nextChap.offset-currChap.offset;
    }
    
    //NSLog(@"offset=%llu,length=%llu",offset,length);
    if(offset>_utxContentLength||length>_utxContentLength)
    {
        NSLog(@"非法offset与length,超过文件预期大小");
        return nil;
    }
    
    //最好还要检验这些数据的合法性，以避免出错呢???
    if(_utxHandle)
    {
        [_utxHandle seekToFileOffset:offset];
        NSData *data=[_utxHandle readDataOfLength:length];
        content=[self dataToUnicodeString:data];
    }
    
    return content;
}


@end
