//
//  BrowserItem.h
//  Photo Renamer
//
//  Created by Gandalf Hernandez on 2/11/13.
//  Copyright (c) 2013 Gandalf Hernandez. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BrowserItem : NSObject

- initWithFolder:(NSString *)folder name:(NSString *)name;

@property (nonatomic, readonly) NSString *folder;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) NSString *rename;
@property (nonatomic, readonly) BOOL isFolder;

@end
