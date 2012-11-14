//
//  BrowserItem.m
//  Photo Renamer
//
//  Created by Gandalf Hernandez on 2/11/13.
//  Copyright (c) 2013 Gandalf Hernandez. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "BrowserItem.h"

@interface BrowserItem ()
{
}

@end

@implementation BrowserItem

- initWithFolder:(NSString *)folder name:(NSString *)name
{
  if (self = [super init]) {
    _folder = folder;
    _name = name;
    _rename = name;

    BOOL isFolder = FALSE;
    [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isFolder];
    _isFolder = isFolder;
  }
  return self;
}

- (id)path
{
  return [self.folder stringByAppendingPathComponent:self.name];
}

#pragma mark -
#pragma mark item data source protocol

- (NSString *)imageRepresentationType
{
	return IKImageBrowserPathRepresentationType;
}

- (id)imageRepresentation
{
  return self.path;
}

- (NSString *)imageUID
{
  return self.path;
}

- (NSString *)imageTitle
{
  return self.isFolder ? self.name : self.rename;
}

- (NSString *)imageSubtitle
{
  return self.isFolder ? @"" : self.name;
}

@end
