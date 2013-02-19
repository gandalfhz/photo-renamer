//
//  Copyright (c) 2012-2013 Gandalf Hernandez.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
