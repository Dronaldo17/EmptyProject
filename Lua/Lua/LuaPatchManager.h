//
// Created by apple on 13-4-5.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LuaPatchManager : NSObject
{
    // 当前软件的版本
    // 用来检测当前用户所使用的版本和服务器版本之间的差别，用来确定到底是下载哪些更新文件
    NSString *_currentSoftVersion;

    // 在本地存在补丁文件的路径
    NSString * _localPatchFileDir;

    // 在服务器上存放patch的路径
    NSString *_serverPatchFilePath;

    // 是否需要更新
    BOOL _isUpdate;

    // 是否需要强制更新
    BOOL isForce;

}

-(void) startPutPatch:(NSString *) url;


@end