//
// Created by apple on 13-4-5.
//
// To change the template use AppCode | Preferences | File Templates.
//



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   包导入部分
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#import "LuaPatchManager.h"
#import "ZipArchive.h"
#import "SBJson.h"
#import "SysConfig.h"
#import "luaconf.h"
#import "wax.h"



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   宏定义部分
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define kRequestType @"type"

#define kConfigRequest @"config"

#define kPatchRequest @"patch"

#define kPatchURL @"patchURL"

#define kPatchMD5 @"PatchMD5"

#define kServerVersion @"ServerVersion"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   初始化定义部分
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
@implementation LuaPatchManager
DEF_SINGLETON(LuaPatchManager)

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   公有方法实现
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)startPutPatch:(NSString *)url {
    if (nil == url || [url empty]) {
        BeeCC(@"补丁的路径为空，无法进行下载");
        return;
    }
    [self setEvnAndStartLuaPatch];
    // 首先下载一个配置文件包
    BeeRequest *downloadConfigRequest = [self GET:url];
    downloadConfigRequest.userInfo[kRequestType] = kConfigRequest;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   回调相关的方法实现
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)handleRequest:(BeeRequest *)request {
    if ([request.userInfo[kRequestType] isEqualToString:kConfigRequest]) {
        [self requestWithConfigFile:request];
    } else if ([request.userInfo[kRequestType] isEqualToString:kPatchRequest]) {
        [self requestWithPatchFile:request];
    }
}


/**
* 这里是下载配置文件的回调函数处理
*/
- (void)requestWithConfigFile:(BeeRequest *)request {
    if (request.sending) {

    } else if (request.succeed) {
        NSString *str = request.responseString;
        if (nil == str || [str empty]) {
            return;
        }
        NSDictionary *dic = [str objectFromJSONString];
        if (dic) {

            // 校验是否是最新的客户端版本
            if (NO == [self checkAppVersionIsLastVersion:dic]) {
                //TODO:提示用户有最新的版本，需要进行升级
                BeeCC(@"提示用户有最新的版本，需要进行升级");
                return;
            }


            // 校验当前的补丁是否是最新的
            if (NO == [self checkCurrentPatchMD5:dic]) {
                //TODO:当前的补丁是最新的，设置环境即可
                BeeCC(@"当前的补丁是最新的，设置环境即可");
                return;
            }

            // 去网上下载最新patch
            [self downloadPatchFormServer:dic];
        }
    } else if (request.failed) {

    } else if (request.cancelled) {

    }
}

/**
* 设置脚本环境，并且启动脚本
*/
- (void)setEvnAndStartLuaPatch {
    NSString *luaEnv = [[BeeSandbox docPath] stringByAppendingPathComponent:@"DP_Patch"];
    NSString *pp = [NSString stringWithFormat:@"%@/?.lua", luaEnv];

    // 设置lua环境
    setenv(LUA_PATH, [pp UTF8String], 1);
    // 启动
    wax_start("patch", nil);
}

/**
* 去网上下载patch
*/
- (void)downloadPatchFormServer:(NSDictionary *)dic {
    NSString *patchUrl = dic[kPatchURL];
    if (nil != patchUrl && [patchUrl notEmpty]) {
        // 开始下载补丁包
        BeeRequest *downloadPatchRequest = [self GET:patchUrl];
        downloadPatchRequest.userInfo[kRequestType] = kPatchRequest;
    }
}

/**
* 校验当前版本是不是最新的版本
*/

- (BOOL)checkAppVersionIsLastVersion:(NSDictionary *)dic {
    // 校验是否是最新的客户端版本
    NSString *lastVersion = dic[kServerVersion];
    CGFloat fCurrentVersion = [SysConfig getCurrentVerson].floatValue;
    if (nil != lastVersion && [lastVersion notEmpty]) {
        CGFloat fLastVersion = lastVersion.floatValue;
        if (fLastVersion > fCurrentVersion) {
            BeeCC(@"提示用户有最新的版本，需要进行升级");
            return NO;
        }
    }
    return YES;
}


/**
* 检测当前补丁是不是最新的补丁文件
*/
- (BOOL)checkCurrentPatchMD5:(NSDictionary *)dic {
    // 校验当前的补丁是否是最新的
    NSString *patchMD5 = dic[kPatchMD5];
    NSString *patchLocalPath = [NSString stringWithFormat:@"%@/DP_Patch/luaPatch.zip", [BeeSandbox docPath]];
    if (nil != patchLocalPath && [patchLocalPath notEmpty]) {
        NSString *localPatchPathMD5 = [[NSData dataWithContentsOfFile:patchLocalPath] MD5String];
        if (nil != patchMD5 && [patchMD5 notEmpty]) {
            if ([[patchMD5 uppercaseString] isEqualToString:[localPatchPathMD5 uppercaseString]]) {
                return NO;
            }
        }
    }
    return YES;
}


/**
* 这里是下载补丁路径的文件回调
*/
- (void)requestWithPatchFile:(BeeRequest *)request {
    if (request.sending) {

    } else if (request.succeed) {
        // 补丁下载成功，在这里进行解压操作
        // 因为解压有可能会非常耗时，需要考虑是否在一个单独的现成中进行解压

        // 创建一个Lua脚本环境
        NSString *luaEnv = [self createLuaPathEvn];
        NSString *patchSavePath = [NSString stringWithFormat:@"%@/luaPatch.zip", luaEnv];
        // 将数据写入到一个文件中
        [self writeData:request.responseData toZipFile:patchSavePath];
        // 将文件解压到指定的文件夹中
        [self unZipLuaPathFile:patchSavePath ToDir:luaEnv];
        BeeCC(@"补丁下载成功,存储路径 = %@", patchSavePath);
    } else if (request.failed) {
        BeeCC(@"补丁下载失败");
    } else if (request.cancelled) {
        BeeCC(@"补丁连接超时");
    }
}

/**
* 将服务器中下载的数据，写入到一个文件中
*/
- (void)writeData:(NSData *)data toZipFile:(NSString *)zipFilePath {
    if (nil == data || nil == zipFilePath) {
        return;
    }
    [data writeToFile:zipFilePath atomically:YES];
}


/**
* 将LuaPatch的压缩包解压到指定的补丁目录中
*/
- (void)unZipLuaPathFile:(NSString *)luaPatchFile ToDir:(NSString *)targetDir {
    ZipArchive *zip = [[[ZipArchive alloc] init] autorelease];
    // 解压zip
    [zip UnzipOpenFile:luaPatchFile];
    // 将解压后的文件写入到指定的文件夹中
    [zip UnzipFileTo:targetDir overWrite:YES];
}


/**
* 创建一个Lua脚本环境
* 就是存放Lua脚本的在沙盒中的存放位置
*/
- (NSString *)createLuaPathEvn {
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *luaEnv = [doc stringByAppendingPathComponent:@"DP_Patch"];
    NSError *deleteItemError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:luaEnv error:&deleteItemError];
    if (deleteItemError) {
        BeeCC(@"删除文件夹中的已有项目失败 = %@", deleteItemError.description);
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:luaEnv withIntermediateDirectories:YES attributes:nil error:nil];
    return luaEnv;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
*
*                   Dealloc
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (void)dealloc {


    [super dealloc];
}

@end